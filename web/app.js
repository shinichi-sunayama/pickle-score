// Screen logic. All scoring rules live in core.js.
import {
  DEFAULT_CONFIG, normalizeConfig, createMatch, matchState, recordRally, undoRally, canUndo,
  scoreCall, serveSide,
} from "./core.js";

const APP_VERSION = "0.1.0"; // keep in sync with CACHE_NAME in sw.js
const STORE_MATCH = "pickle-score.match";
const STORE_PREFS = "pickle-score.prefs";
const TEAM_NAMES = ["自分たち", "相手"];
const TAP_GUARD_MS = 400; // ignore a second tap this soon (prevents double counting)

const DEFAULT_PREFS = { voice: "off", vibrate: true, wakeLock: true };

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
      const restored = { config: normalizeConfig(m.config), results: m.results };
      matchState(restored); // validate
      return restored;
    }
  } catch { /* fall through to a new match */ }
  return createMatch(DEFAULT_CONFIG);
}

let match = loadMatch();
let prefs = { ...DEFAULT_PREFS, ...(load(STORE_PREFS) || {}) };
let lastTap = 0;

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

  const call = scoreCall(s);
  $("call").textContent = call;
  $("call").classList.toggle("long", call.length > 6);

  const ev = $("event");
  ev.textContent = eventText || " ";
  ev.classList.toggle("change", eventKind === "change");

  const side = serveSide(s);
  const right = side === "right";
  $("sideText").textContent = right ? "右" : "左";
  $("courtRight").classList.toggle("on", right);
  $("courtLeft").classList.toggle("on", !right);
  $("labelRight").classList.toggle("on", right);
  $("labelLeft").classList.toggle("on", !right);
  $("serverText").textContent = serverLabel(s);

  const over = s.winner !== null;
  $("wonBtn").disabled = over;
  $("lostBtn").disabled = over;
  $("undoBtn").disabled = !canUndo(match);

  $("speakBtn").setAttribute("aria-pressed", String(prefs.voice !== "off"));
  $("speakBtn").textContent = prefs.voice === "off" ? "🔈 読み上げ" : "🔊 読み上げ";

  const overBox = $("over");
  if (over) {
    const w = s.winner;
    $("overTitle").textContent = `${TEAM_NAMES[w]}の勝ち`;
    $("overScore").textContent = `${s.score[w]}-${s.score[1 - w]}`;
    overBox.hidden = false;
  } else {
    overBox.hidden = true;
  }
}

// ---------- what just happened (for the small message and voice) ----------
function describeChange(prev, next) {
  if (next.winner !== null) return { text: "ゲーム終了", kind: "change", ja: "ゲーム終了", en: "game" };
  if (next.serving !== prev.serving) {
    const text = next.score[next.serving] !== prev.score[next.serving]
      ? "レシーブ側に得点・サーブ交代" : "サイドアウト（サーブ交代）";
    return { text, kind: "change", ja: "サイドアウト", en: "side out" };
  }
  if (next.serverNumber !== prev.serverNumber) {
    return { text: "2人目のサーバーへ", kind: "change", ja: "セカンドサーバー", en: "second server" };
  }
  return { text: "得点！", kind: "", ja: "", en: "" };
}

// ---------- voice / vibration / screen ----------
function speak(prefix, state) {
  if (prefs.voice === "off" || !("speechSynthesis" in window)) return;
  const nums = scoreCall(state).split("-");
  let text;
  if (state.winner !== null) {
    const w = state.winner;
    text = prefs.voice === "ja"
      ? `ゲーム終了。${state.score[w]}対${state.score[1 - w]}`
      : `game. ${state.score[w]} to ${state.score[1 - w]}`;
  } else {
    text = prefs.voice === "ja" ? nums.join("、") : nums.join(", ");
    if (prefix) text = `${prefix}。${text}`;
  }
  try {
    speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.lang = prefs.voice === "ja" ? "ja-JP" : "en-US";
    u.rate = prefs.voice === "ja" ? 1.05 : 1.0;
    speechSynthesis.speak(u);
  } catch { /* speech not available */ }
}

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
  if (!tapAllowed()) return;
  const prev = matchState(match);
  if (prev.winner !== null) return;
  match = recordRally(match, servingSideWon);
  save(STORE_MATCH, match);
  const next = matchState(match);
  const ev = describeChange(prev, next);
  render(ev.text, ev.kind);
  buzz(ev.kind === "change" ? [40, 60, 40] : 30);
  speak(prefs.voice === "ja" ? ev.ja : ev.en, next);
  updateWakeLock();
}

function undo() {
  if (!canUndo(match)) return;
  match = undoRally(match);
  save(STORE_MATCH, match);
  render("1つ戻しました", "");
  buzz(20);
  speak("", matchState(match));
}

function newMatch(config = match.config, ask = true) {
  if (ask && canUndo(match) && matchState(match).winner === null
      && !confirm("いまの試合を終えて、新しい試合を始めますか？")) return false;
  match = createMatch(config);
  save(STORE_MATCH, match);
  render("新しい試合", "");
  speak("", matchState(match));
  return true;
}

$("wonBtn").addEventListener("click", () => play(true));
$("lostBtn").addEventListener("click", () => play(false));
$("undoBtn").addEventListener("click", undo);
$("overUndo").addEventListener("click", undo);
$("newBtn").addEventListener("click", () => newMatch());
$("overNew").addEventListener("click", () => newMatch(match.config, false));
$("speakBtn").addEventListener("click", () => {
  prefs.voice = prefs.voice === "off" ? "ja" : "off";
  save(STORE_PREFS, prefs);
  render();
  if (prefs.voice !== "off") speak("", matchState(match));
});

// ---------- settings ----------
const dialog = $("settings");
const form = $("settingsForm");

function setRadio(name, value) {
  for (const el of form.elements[name]) el.checked = el.value === String(value);
}
function getRadio(name) {
  for (const el of form.elements[name]) if (el.checked) return el.value;
  return null;
}

function deviceNote() {
  const notes = [];
  if (!canVibrate) notes.push("この端末のブラウザは振動に対応していません（iPhone の Safari は非対応です）。");
  if (!("wakeLock" in navigator)) notes.push("この端末のブラウザは「画面を消さない」に対応していません。");
  if (!("speechSynthesis" in window)) notes.push("この端末のブラウザは読み上げに対応していません。");
  return notes.join(" ");
}

$("rulesBtn").addEventListener("click", () => {
  const c = match.config;
  setRadio("players", c.players);
  setRadio("scoring", c.scoring);
  setRadio("target", c.target);
  setRadio("winBy", c.winBy);
  setRadio("firstServer", c.firstServer);
  setRadio("voice", prefs.voice);
  form.elements.vibrate.checked = prefs.vibrate;
  form.elements.wakeLock.checked = prefs.wakeLock;
  $("deviceNote").textContent = deviceNote();
  $("version").textContent = `v${APP_VERSION}`;
  dialog.showModal();
});

dialog.addEventListener("close", () => {
  if (dialog.returnValue !== "save") return;
  prefs = {
    voice: getRadio("voice") || "off",
    vibrate: form.elements.vibrate.checked,
    wakeLock: form.elements.wakeLock.checked,
  };
  save(STORE_PREFS, prefs);
  updateWakeLock();

  const config = normalizeConfig({
    players: getRadio("players"),
    scoring: getRadio("scoring"),
    target: Number(getRadio("target")),
    winBy: Number(getRadio("winBy")),
    firstServer: Number(getRadio("firstServer")),
  });
  const changed = JSON.stringify(config) !== JSON.stringify(match.config);
  if (changed) {
    const started = canUndo(match) && matchState(match).winner === null;
    if (!started || confirm("ルールを変えると新しい試合になります。よろしいですか？")) {
      newMatch(config, false);
      return;
    }
  }
  render();
});

// ---------- start ----------
render();
updateWakeLock();

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("sw.js").catch(() => { /* offline support unavailable */ });
  });
}
