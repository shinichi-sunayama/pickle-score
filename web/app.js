// Screen logic. All scoring rules live in core.js; reading aloud lives in voice.js.
import {
  DEFAULT_CONFIG, normalizeConfig, createMatch, matchState, recordRally, undoRally, canUndo,
  scoreCall, serveSide,
} from "./core.js";
import { callTokens, createSpeaker } from "./voice.js";
import { recordFromMatch, upsertHistory, removeFromHistory, timeline, sanitizeHistory } from "./history.js";

const APP_VERSION = "0.4.3"; // keep in sync with CACHE_NAME in sw.js
const STORE_MATCH = "pickle-score.match";
const STORE_PREFS = "pickle-score.prefs";
const STORE_HISTORY = "pickle-score.history";
const DOGS = ["ohagi", "kinako", "shiratama", "dorayaki", "yokan"];
const TEAM_NAMES = ["自分たち", "相手"];
const TAP_GUARD_MS = 400; // ignore a second tap this soon (prevents double counting)

const DEFAULT_PREFS = { voice: "off", lastVoice: "ja", vibrate: true, wakeLock: true };

const $ = (id) => document.getElementById(id);

// ---------- storage (local to this device only) ----------
function load(key) {
  try { const v = localStorage.getItem(key); return v ? JSON.parse(v) : null; } catch { return null; }
}
function save(key, value) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* storage may be unavailable */ }
}

function loadMatch() {
  const m = load(STORE_MATCH);
  try {
    if (m && typeof m.results === "string" && /^[WL]*$/.test(m.results)) {
      const restored = { id: typeof m.id === "string" ? m.id : newId(), config: normalizeConfig(m.config), results: m.results };
      matchState(restored); // validate
      return restored;
    }
  } catch { /* fall through to a new match */ }
  return freshMatch(DEFAULT_CONFIG);
}

function newId() {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`;
}
function freshMatch(config) {
  return { ...createMatch(config), id: newId() };
}

let match = loadMatch();
let prefs = { ...DEFAULT_PREFS, ...(load(STORE_PREFS) || {}) };
let gameHistory = sanitizeHistory(load(STORE_HISTORY));
let lastTap = 0;
const speaker = createSpeaker();
speaker.setMode(prefs.voice);

// ---------- rendering ----------
function rulesLabel(c) {
  const parts = [c.players === "doubles" ? "ダブルス" : "シングルス"];
  if (c.scoring === "rally") parts.push("毎ラリー");
  parts.push(`${c.target}点${c.winBy === 1 ? "（1点差）" : ""}`);
  return parts.join("・");
}

function serverLabel(s) {
  if (s.config.players === "singles") return "";
  const who = s.serverIsStarter ? "開始時に右の人" : "開始時に左の人";
  return s.serverNumber ? `サーバー${s.serverNumber}：${who}` : `サーバー：${who}`;
}

function voiceName(id) {
  if (id === "off") return "なし";
  if (id === "ja") return "端末の声";
  if (id === "en") return "英語の声";
  const v = speaker.voices.find((x) => x.id === id);
  return v ? v.name : "端末の声";
}

function render(eventText = "", eventKind = "") {
  const s = matchState(match);
  const c = s.config;

  $("rulesText").textContent = rulesLabel(c);
  $("rallyCount").textContent = `ラリー ${s.rallies}`;

  for (const t of [0, 1]) {
    $(`teamName${t}`).textContent = TEAM_NAMES[t];
    $(`teamScore${t}`).textContent = s.score[t];
    $(`team${t}`).classList.toggle("serving", s.winner === null && s.serving === t);
  }

  const callEl = $("call");
  const call = scoreCall(s);
  callEl.textContent = call;
  for (const n of [6, 7, 8]) callEl.classList.toggle(`len${n}`, Math.min(call.length, 8) === n);
  if (eventText) { callEl.classList.remove("bump"); void callEl.offsetWidth; callEl.classList.add("bump"); }

  const ev = $("event");
  ev.hidden = !eventText;
  ev.textContent = eventText;
  ev.className = `event ${eventKind}`;
  if (eventText) { ev.style.animation = "none"; void ev.offsetWidth; ev.style.animation = ""; }

  const right = serveSide(s) === "right";
  $("sideText").textContent = right ? "右" : "左";
  $("courtRight").classList.toggle("on", right);
  $("courtLeft").classList.toggle("on", !right);
  $("labelRight").classList.toggle("on", right);
  $("labelLeft").classList.toggle("on", !right);
  $("serverText").textContent = serverLabel(s);
  $("serverText").hidden = !serverLabel(s);

  const over = s.winner !== null;
  $("wonBtn").disabled = over;
  $("lostBtn").disabled = over;
  $("undoBtn").disabled = !canUndo(match);

  const on = prefs.voice !== "off";
  $("speakBtn").setAttribute("aria-pressed", String(on));
  $("speakIco").textContent = on ? "🔊" : "🔈";
  $("speakText").textContent = on ? voiceName(prefs.voice) : "読み上げ";

  if (over) {
    const w = s.winner;
    $("overTitle").textContent = `${TEAM_NAMES[w]}の勝ち`;
    $("overScore").textContent = `${s.score[w]}-${s.score[1 - w]}`;
    if ($("over").hidden) {
      // A different dog cheers each game (chosen from the game id so it stays the same on reload).
      const k = [...match.id].reduce((a, ch) => a + ch.charCodeAt(0), 0) % DOGS.length;
      $("overDog").src = `img/dogs/${DOGS[k]}.png`;
    }
  }
  $("over").hidden = !over;
}

// ---------- what just happened (for the small message and voice) ----------
function describeChange(prev, next) {
  if (next.winner !== null) return { text: "ゲームセット", kind: "change", phrase: "gameset" };
  if (next.serving !== prev.serving) {
    const text = next.score[next.serving] !== prev.score[next.serving]
      ? "レシーブ側に得点・サーブ交代" : "サイドアウト（サーブ交代）";
    return { text, kind: "change", phrase: "sideout" };
  }
  if (next.serverNumber !== prev.serverNumber) return { text: "2人目のサーバーへ", kind: "change", phrase: "second" };
  return { text: "得点！", kind: "", phrase: "" };
}

// ---------- vibration / screen ----------
const canVibrate = typeof navigator.vibrate === "function";
function buzz(pattern) {
  if (prefs.vibrate && canVibrate) { try { navigator.vibrate(pattern); } catch { /* ignore */ } }
}

let wakeLock = null;
async function updateWakeLock() {
  const want = prefs.wakeLock && document.visibilityState === "visible" && "wakeLock" in navigator;
  if (want && !wakeLock) {
    try {
      wakeLock = await navigator.wakeLock.request("screen");
      wakeLock.addEventListener("release", () => { wakeLock = null; });
    } catch { wakeLock = null; }
  } else if (!want && wakeLock) {
    try { await wakeLock.release(); } catch { /* ignore */ }
    wakeLock = null;
  }
}
document.addEventListener("visibilitychange", updateWakeLock);

// ---------- actions ----------
function tapAllowed() {
  const now = Date.now();
  if (now - lastTap < TAP_GUARD_MS) return false;
  lastTap = now;
  return true;
}

function play(servingSideWon) {
  speaker.unlock();
  if (!tapAllowed()) return;
  const prev = matchState(match);
  if (prev.winner !== null) return;
  match = recordRally(match, servingSideWon);
  save(STORE_MATCH, match);
  const next = matchState(match);
  if (next.winner !== null) saveToHistory();
  const ev = describeChange(prev, next);
  render(ev.text, ev.kind);
  buzz(ev.kind === "change" ? [40, 60, 40] : 30);
  speaker.say(callTokens(next, ev.phrase));
  updateWakeLock();
}

function undo() {
  speaker.unlock();
  if (!canUndo(match)) return;
  // Undoing the last point of a finished game reopens it, so it leaves the gameHistory for now.
  if (matchState(match).winner !== null) { gameHistory = removeFromHistory(gameHistory, match.id); save(STORE_HISTORY, gameHistory); }
  match = undoRally(match);
  save(STORE_MATCH, match);
  render("1つ戻しました", "info");
  buzz(20);
  speaker.say(callTokens(matchState(match)));
}

function saveToHistory() {
  if (!canUndo(match)) return; // nothing played
  gameHistory = upsertHistory(gameHistory, recordFromMatch(match, Date.now()));
  save(STORE_HISTORY, gameHistory);
}

function startNewMatch(config) {
  saveToHistory(); // keeps a game stopped halfway too (finished games are already saved)
  match = freshMatch(config);
  save(STORE_MATCH, match);
  render("新しい試合", "info");
  speaker.say(callTokens(matchState(match)));
}

function newMatchAsked() {
  speaker.unlock();
  if (canUndo(match) && matchState(match).winner === null
      && !confirm("いまの試合を終えて、新しい試合を始めますか？")) return;
  startNewMatch(match.config);
}

$("wonBtn").addEventListener("click", () => play(true));
$("lostBtn").addEventListener("click", () => play(false));
$("undoBtn").addEventListener("click", undo);
$("overUndo").addEventListener("click", undo);
$("newBtn").addEventListener("click", newMatchAsked);
$("overNew").addEventListener("click", () => { speaker.unlock(); startNewMatch(match.config); });
$("speakBtn").addEventListener("click", () => {
  speaker.unlock();
  if (prefs.voice === "off") prefs.voice = prefs.lastVoice || "ja";
  else { prefs.lastVoice = prefs.voice; prefs.voice = "off"; }
  speaker.setMode(prefs.voice);
  save(STORE_PREFS, prefs);
  render();
  speaker.say(callTokens(matchState(match)));
});

// ---------- gameHistory ----------
const historyDialog = $("history");

function rulesShort(c) {
  return rulesLabel(normalizeConfig(c));
}

function whenLabel(ms) {
  const d = new Date(ms);
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getMonth() + 1}/${d.getDate()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function el(tag, cls, text) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text !== undefined) e.textContent = text;
  return e;
}

function renderHistory() {
  const box = $("historyList");
  box.replaceChildren();
  if (!gameHistory.length) { box.append(el("div", "hist-empty", "まだ試合の記録はありません")); return; }
  for (const r of gameHistory) {
    let config;
    try { config = normalizeConfig(r.config); } catch { continue; }
    const finished = r.winner === 0 || r.winner === 1;
    const item = el("details", `hist-item${finished ? "" : " unfinished"}`);
    const sum = el("summary");
    sum.append(
      el("span", "hist-when", whenLabel(r.endedAt)),
      el("span", "hist-rules", rulesShort(config)),
      el("span", "hist-result", finished ? `${TEAM_NAMES[r.winner]}の勝ち` : "途中まで"),
      el("span", "hist-score", `${r.score[0]}-${r.score[1]}`),
    );
    item.append(sum);
    // Build the rally list only when opened (keeps the dialog quick).
    item.addEventListener("toggle", () => {
      if (!item.open || item.querySelector(".hist-rows")) return;
      const ol = el("ol", "hist-rows");
      const head = el("li");
      head.append(el("span", "n", "#"), el("span", "c", "コール"), el("span", "r", "そのラリー"));
      ol.append(head);
      for (const row of timeline(config, r.results)) {
        const li = el("li");
        let res;
        if (row.result === "W") res = el("span", "r w", `${TEAM_NAMES[row.serving]}がサーブで取った`);
        else if (row.result === "L") res = el("span", "r l", `${TEAM_NAMES[row.serving]}がサーブで落とした`);
        else res = el("span", "r", row.winner !== null ? "ゲームセット" : "ここで終了");
        li.append(el("span", "n", row.result ? String(row.n) : ""), el("span", "c", row.call), res);
        ol.append(li);
      }
      item.append(ol);
    });
    box.append(item);
  }
}

$("historyBtn").addEventListener("click", () => { renderHistory(); historyDialog.showModal(); });
$("historyClose").addEventListener("click", () => historyDialog.close());
$("historyClear").addEventListener("click", () => {
  if (!gameHistory.length || !confirm("試合の履歴をすべて消しますか？（もとに戻せません）")) return;
  gameHistory = [];
  save(STORE_HISTORY, gameHistory);
  renderHistory();
});

// ---------- settings ----------
const dialog = $("settings");
const form = $("settingsForm");

function radios(name) {
  const r = form.elements[name];
  return r instanceof RadioNodeList ? [...r] : [r];
}
function setRadio(name, value) {
  for (const el of radios(name)) el.checked = el.value === String(value);
}
function getRadio(name) {
  const el = radios(name).find((e) => e.checked);
  return el ? el.value : null;
}

function deviceNote() {
  const notes = [];
  if (!canVibrate) notes.push("この端末のブラウザは振動に対応していません（iPhone の Safari は非対応です）。");
  if (!("wakeLock" in navigator)) notes.push("この端末のブラウザは「画面を消さない」に対応していません。");
  return notes.join(" ");
}

function addVoiceChoices() {
  const box = $("voiceChoices");
  for (const v of speaker.voices) {
    if (box.querySelector(`input[value="${v.id}"]`)) continue;
    const label = document.createElement("label");
    label.innerHTML = `<input type="radio" name="voice"><span></span>`;
    label.querySelector("input").value = v.id;
    label.querySelector("span").textContent = v.name;
    box.append(label);
  }
  const credits = ["フォント：M PLUS Rounded 1c（SIL Open Font License 1.1）"];
  for (const v of speaker.voices) credits.push(v.credit);
  $("credits").textContent = credits.join(" ／ ");
}

$("rulesBtn").addEventListener("click", () => {
  speaker.unlock();
  addVoiceChoices();
  const c = match.config;
  setRadio("players", c.players);
  setRadio("scoring", c.scoring);
  setRadio("target", c.target);
  setRadio("winBy", c.winBy);
  setRadio("firstServer", c.firstServer);
  setRadio("voice", prefs.voice);
  if (!getRadio("voice")) setRadio("voice", "ja");
  form.elements.vibrate.checked = prefs.vibrate;
  form.elements.wakeLock.checked = prefs.wakeLock;
  $("deviceNote").textContent = deviceNote();
  $("version").textContent = `v${APP_VERSION}`;
  dialog.showModal();
});

// Preview a voice when it is picked.
$("voiceChoices").addEventListener("change", (e) => {
  if (e.target.name !== "voice") return;
  speaker.unlock();
  speaker.setMode(e.target.value);
  speaker.say(callTokens(matchState(match)));
});

dialog.addEventListener("close", () => {
  if (dialog.returnValue !== "save") { speaker.setMode(prefs.voice); return; }
  const voice = getRadio("voice") || "off";
  prefs = {
    voice,
    lastVoice: voice !== "off" ? voice : prefs.lastVoice,
    vibrate: form.elements.vibrate.checked,
    wakeLock: form.elements.wakeLock.checked,
  };
  speaker.setMode(prefs.voice);
  save(STORE_PREFS, prefs);
  updateWakeLock();

  const config = normalizeConfig({
    players: getRadio("players"),
    scoring: getRadio("scoring"),
    target: Number(getRadio("target")),
    winBy: Number(getRadio("winBy")),
    firstServer: Number(getRadio("firstServer")),
  });
  if (JSON.stringify(config) !== JSON.stringify(match.config)) {
    const started = canUndo(match) && matchState(match).winner === null;
    if (!started || confirm("ルールを変えると新しい試合になります。よろしいですか？")) {
      startNewMatch(config);
      return;
    }
  }
  render();
});

// ---------- start ----------
render();
updateWakeLock();
speaker.ready.then(() => { speaker.setMode(prefs.voice); render(); });

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("sw.js").catch(() => { /* offline support unavailable */ });
  });
}
