// Tests for web/core.js. Runs in the browser (tests/index.html) and in Node (tests/run-node.mjs).
import {
  newGame, playRally, replay, scoreCall, serveSide, normalizeConfig,
  createMatch, matchState, recordRally, undoRally, canUndo,
} from "../web/core.js";

function describeState(s) {
  return `${scoreCall(s)} ${serveSide(s) === "right" ? "R" : "L"} T${s.serving}`;
}

function eq(actual, expected, label) {
  const a = JSON.stringify(actual), e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${label}: expected ${e}, got ${a}`);
}

function throws(fn, label) {
  try { fn(); } catch { return; }
  throw new Error(`${label}: expected an error`);
}

function caseTests(data) {
  return data.cases.map((c) => [`case: ${c.name}`, () => {
    for (const [at, want] of Object.entries(c.checks)) {
      const s = replay(c.config, c.results.slice(0, Number(at)));
      eq(describeState(s), want, `after ${at} rallies`);
    }
    const end = replay(c.config, c.results);
    eq(end.winner, c.winner, "winner");
    eq(end.rallies, c.rallies, "rallies counted");
  }]);
}

const unitTests = [
  ["default game starts 0-0-2 from the right", () => {
    const s = newGame();
    eq(scoreCall(s), "0-0-2", "call");
    eq(serveSide(s), "right", "side");
    eq(s.winner, null, "winner");
  }],
  ["playRally does not modify its input", () => {
    const s = newGame();
    const before = JSON.stringify(s);
    playRally(s, true);
    playRally(s, false);
    eq(JSON.stringify(s), before, "state unchanged");
  }],
  ["no rally counts after the game is over", () => {
    let s = replay({}, "WWWWWWWWWWW");
    eq(s.winner, 0, "winner");
    const after = playRally(s, false);
    eq(after, s, "same state");
  }],
  ["match: record, undo, canUndo", () => {
    let m = createMatch();
    eq(canUndo(m), false, "nothing to undo at start");
    m = recordRally(m, true);
    m = recordRally(m, false);
    eq(m.results, "WL", "results");
    eq(scoreCall(matchState(m)), "0-1-1", "call after W L");
    m = undoRally(m);
    eq(scoreCall(matchState(m)), "1-0-2", "call after undo");
    m = undoRally(m);
    eq(scoreCall(matchState(m)), "0-0-2", "back to start");
    eq(canUndo(m), false, "nothing left to undo");
    eq(undoRally(m).results, "", "undo at start is harmless");
  }],
  ["match: undo after a win reopens the game", () => {
    let m = createMatch({ players: "singles" });
    for (let i = 0; i < 11; i++) m = recordRally(m, true);
    eq(matchState(m).winner, 0, "won");
    eq(recordRally(m, true).results.length, 11, "extra rally not recorded");
    m = undoRally(m);
    eq(matchState(m).winner, null, "not won after undo");
    eq(scoreCall(matchState(m)), "10-0", "call");
  }],
  ["match survives a JSON round trip (saved game)", () => {
    let m = createMatch({ scoring: "rally", target: 15 });
    m = recordRally(recordRally(m, true), false);
    const back = JSON.parse(JSON.stringify(m));
    eq(scoreCall(matchState(back)), scoreCall(matchState(m)), "same call");
    eq(back.config.target, 15, "config kept");
  }],
  ["normalizeConfig rejects bad values", () => {
    throws(() => normalizeConfig({ players: "triples" }), "players");
    throws(() => normalizeConfig({ scoring: "x" }), "scoring");
    throws(() => normalizeConfig({ target: 0 }), "target 0");
    throws(() => normalizeConfig({ target: 10.5 }), "target fraction");
    throws(() => normalizeConfig({ winBy: 0 }), "winBy");
    throws(() => normalizeConfig({ firstServer: 2 }), "firstServer");
    throws(() => replay({}, "WX"), "bad result letter");
  }],
  ["serve side always right right after a doubles side out", () => {
    // Rule 5.B.2 / 14.A.4: after each side out, service begins from the right.
    for (const scoring of ["sideout", "rally"]) {
      let s = newGame({ scoring });
      const rng = mulberry32(42);
      for (let i = 0; i < 400 && s.winner === null; i++) {
        const prevServing = s.serving;
        s = playRally(s, rng() < 0.55);
        if (s.serving !== prevServing && s.winner === null) eq(serveSide(s), "right", `${scoring} rally ${i}`);
      }
    }
  }],
  ["random games: invariants hold", () => {
    const rng = mulberry32(7);
    for (let g = 0; g < 200; g++) {
      const config = {
        players: rng() < 0.5 ? "doubles" : "singles",
        scoring: rng() < 0.5 ? "sideout" : "rally",
        target: [11, 15, 21][Math.floor(rng() * 3)],
        winBy: rng() < 0.8 ? 2 : 1,
      };
      let s = newGame(config);
      let guard = 0;
      while (s.winner === null && guard++ < 5000) {
        const prev = s;
        s = playRally(s, rng() < 0.5);
        const gained = s.score[0] + s.score[1] - prev.score[0] - prev.score[1];
        if (gained > 1 || gained < 0) throw new Error("score jumped");
        if (config.scoring === "sideout" && s.score[1 - prev.serving] !== prev.score[1 - prev.serving])
          throw new Error("receiving side scored in side-out scoring");
        if (config.players === "singles" || config.scoring === "rally") eq(s.serverNumber, null, "no server number");
        else if (s.serverNumber !== 1 && s.serverNumber !== 2) throw new Error("bad server number");
      }
      if (s.winner === null) throw new Error("game never ended");
      const w = s.winner;
      if (s.score[w] < config.target || s.score[w] - s.score[1 - w] < config.winBy) throw new Error("bad win");
      // One point earlier the winner must not already have met the win condition.
      if (s.score[w] - 1 >= config.target && s.score[w] - 1 - s.score[1 - w] >= config.winBy)
        throw new Error("game should have ended earlier");
    }
  }],
];

// Small deterministic random number generator so test runs are repeatable.
function mulberry32(seed) {
  return function () {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function runAll(casesData) {
  const results = [];
  for (const [name, fn] of [...caseTests(casesData), ...unitTests]) {
    try { fn(); results.push({ name, ok: true }); }
    catch (e) { results.push({ name, ok: false, error: e.message }); }
  }
  return results;
}
