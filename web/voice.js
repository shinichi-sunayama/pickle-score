// Reading the score call aloud.
// Modes: "off", "ja" (device voice, English numbers in katakana: ゼロ・ゼロ・ツー),
// "en" (device English voice), or a VOICEVOX voice id whose clips are in voices/<id>/.

import { scoreCall } from "./core.js";

// Tokens to say for a state: optional phrase first, then the numbers of the call.
// Phrase tokens: "sideout", "second", "gameset". Number tokens: integers.
export function callTokens(state, phrase = "") {
  if (state.winner !== null) {
    const w = state.winner;
    return ["gameset", state.score[w], state.score[1 - w]];
  }
  const nums = scoreCall(state).split("-").map(Number);
  return phrase ? [phrase, ...nums] : nums;
}

const EN_PHRASES = { sideout: "side out", second: "second server", gameset: "game" };

export function createSpeaker() {
  let words = null; // from voice-words.json
  let voices = []; // from voices/voices.json (generated VOICEVOX clips)
  let mode = "off";
  let ctx = null;
  const buffers = new Map(); // "voiceId/name" -> AudioBuffer
  let playing = [];
  let requestId = 0;

  const ready = Promise.all([
    fetch("voice-words.json").then((r) => r.json()).then((j) => { words = j; }).catch(() => {}),
    fetch("voices/voices.json").then((r) => (r.ok ? r.json() : [])).then((j) => { voices = j; }).catch(() => {}),
  ]);

  function clipName(token) {
    return typeof token === "number" ? `n${token}` : token;
  }

  function isClipVoice(m) {
    return voices.some((v) => v.id === m);
  }

  function hasAllClips(m, tokens) {
    return tokens.every((t) => buffers.has(`${m}/${clipName(t)}`));
  }

  const pending = new Map(); // "voiceId/name" -> Promise (avoid loading a clip twice)
  function loadClip(m, name) {
    const key = `${m}/${name}`;
    if (buffers.has(key) || !ctx) return Promise.resolve();
    if (!pending.has(key)) pending.set(key, fetchClip(m, name, key).finally(() => pending.delete(key)));
    return pending.get(key);
  }

  async function fetchClip(m, name, key) {
    try {
      const res = await fetch(`voices/${m}/${name}.wav`);
      if (!res.ok) return;
      const data = await res.arrayBuffer();
      const buf = await new Promise((ok, ng) => ctx.decodeAudioData(data, ok, ng));
      buffers.set(key, buf);
    } catch { /* missing or undecodable clip: fall back to device voice */ }
  }

  async function preload(m) {
    await ready;
    if (!isClipVoice(m) || !words || !ctx) return;
    const names = [...words.numbers.map((_, i) => `n${i}`), ...Object.keys(words.phrases)];
    await Promise.all(names.map((n) => loadClip(m, n)));
  }

  // Must be called from a tap (iOS only allows audio to start from a user action).
  function unlock() {
    try {
      if (navigator.audioSession) navigator.audioSession.type = "playback"; // play even in silent mode (Safari 16.4+)
    } catch { /* ignore */ }
    if (!ctx) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (AC) ctx = new AC();
      if (ctx && isClipVoice(mode)) preload(mode);
    }
    if (ctx && ctx.state === "suspended") ctx.resume().catch(() => {});
  }

  function stop() {
    for (const s of playing) { try { s.stop(); } catch { /* already stopped */ } }
    playing = [];
    try { if ("speechSynthesis" in window) speechSynthesis.cancel(); } catch { /* ignore */ }
  }

  function playClips(m, tokens) {
    let t = ctx.currentTime + 0.03;
    for (const tok of tokens) {
      const buf = buffers.get(`${m}/${clipName(tok)}`);
      const src = ctx.createBufferSource();
      src.buffer = buf;
      src.connect(ctx.destination);
      src.start(t);
      playing.push(src);
      t += buf.duration + (typeof tok === "number" ? 0.04 : 0.18);
    }
  }

  function speakDevice(lang, tokens) {
    if (!("speechSynthesis" in window)) return;
    let text;
    if (lang === "en") {
      text = tokens.map((t) => (typeof t === "number" ? String(t) : EN_PHRASES[t])).join(", ");
    } else {
      const num = (n) => (words && n < words.numbers.length ? words.numbers[n] : String(n));
      const phrase = (p) => (words ? words.phrases[p] : p);
      text = tokens.map((t) => (typeof t === "number" ? num(t) : `${phrase(t)}。`)).join("、").replace(/。、/g, "。");
    }
    try {
      const u = new SpeechSynthesisUtterance(text);
      u.lang = lang === "en" ? "en-US" : "ja-JP";
      u.rate = 1.05;
      speechSynthesis.speak(u);
    } catch { /* speech not available */ }
  }

  return {
    ready,
    get voices() { return voices; },
    setMode(m) {
      mode = m;
      if (isClipVoice(m)) preload(m);
    },
    unlock,
    say(tokens) {
      stop();
      requestId++;
      if (mode === "off") return;
      if (isClipVoice(mode)) {
        if (ctx && hasAllClips(mode, tokens)) { playClips(mode, tokens); return; }
        const inRange = words && tokens.every((t) => typeof t !== "number" || t < words.numbers.length);
        if (!ctx || !inRange) { speakDevice("ja", tokens); return; } // beyond the clip range
        // Clips still loading (just picked the voice): wait a little, then play.
        const m = mode;
        const id = ++requestId;
        Promise.race([preload(m), new Promise((ok) => setTimeout(ok, 2500))]).then(() => {
          if (id !== requestId || mode !== m) return; // a newer call replaced this one
          if (hasAllClips(m, tokens)) playClips(m, tokens);
          else speakDevice("ja", tokens);
        });
        return;
      }
      speakDevice(mode === "en" ? "en" : "ja", tokens);
    },
  };
}
