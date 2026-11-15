// Pickleball score-calling rules (USA Pickleball Official Rulebook 2026).
// Pure logic with no DOM access, so it can be tested on its own and ported to Swift.
// See docs/rules.md for the rule references.
//
// Teams are numbered 0 and 1. A game is fully described by its config plus the
// list of rally results, where each result is "W" (serving side won the rally)
// or "L" (serving side lost the rally). Undo = drop the last result and replay.

export const DEFAULT_CONFIG = Object.freeze({
  players: "doubles", // "doubles" | "singles"
  scoring: "sideout", // "sideout" (standard, Rule 4.A) | "rally" (Rule 14.A)
  target: 11, // points needed to win (Rule 15.C: 11, 15 or 21)
  winBy: 2, // required lead (Rule 15.C: 2; 1 allowed in team play)
  firstServer: 0, // team that serves first
});

export function normalizeConfig(config = {}) {
  const c = { ...DEFAULT_CONFIG, ...config };
  if (c.players !== "doubles" && c.players !== "singles") throw new Error(`bad players: ${c.players}`);
  if (c.scoring !== "sideout" && c.scoring !== "rally") throw new Error(`bad scoring: ${c.scoring}`);
  if (!Number.isInteger(c.target) || c.target < 1) throw new Error(`bad target: ${c.target}`);
  if (!Number.isInteger(c.winBy) || c.winBy < 1) throw new Error(`bad winBy: ${c.winBy}`);
  if (c.firstServer !== 0 && c.firstServer !== 1) throw new Error(`bad firstServer: ${c.firstServer}`);
  return c;
}

function usesServerNumber(config) {
  return config.players === "doubles" && config.scoring === "sideout";
}

// In doubles, each team's "starter" is the player who stood on the right at 0 points.
// Rule 5.B.3: the starter is on the right when the team score is even, left when odd.
function starterOnRight(teamScore) {
  return teamScore % 2 === 0;
}

export function newGame(config = {}) {
  const c = normalizeConfig(config);
  return {
    config: c,
    score: [0, 0],
    serving: c.firstServer,
    // Rule 5.B / 6.B.2: the team that starts the game has only one server, called server 2.
    serverNumber: usesServerNumber(c) ? 2 : null,
    // Doubles only: whether the current server is the serving team's starter.
    // The first server after any side out is whoever stands on the right (Rule 5.B.2).
    serverIsStarter: true,
    rallies: 0,
    winner: null,
  };
}

function winnerOf(score, config) {
  for (const t of [0, 1]) {
    const other = 1 - t;
    if (score[t] >= config.target && score[t] - score[other] >= config.winBy) return t;
  }
  return null;
}

function sideOut(state, score) {
  const serving = 1 - state.serving;
  return {
    ...state,
    score,
    serving,
    serverNumber: usesServerNumber(state.config) ? 1 : null,
    // The new serving team's first server is the player standing on the right.
    serverIsStarter: starterOnRight(score[serving]),
  };
}

// Apply one rally. servingSideWon: true if the serving side won the rally.
// Returns a new state; the input is not modified. Rallies after the game ends are ignored.
export function playRally(state, servingSideWon) {
  if (state.winner !== null) return state;
  const { config } = state;
  const s = state.serving;
  const r = 1 - s;
  let next;

  if (servingSideWon) {
    // Rule 4.A / 14.A.2: the serving side scores; the same server continues.
    const score = [...state.score];
    score[s] += 1;
    next = { ...state, score };
  } else if (config.scoring === "rally") {
    // Rule 14.A.2 / 14.A.5: the receiving side scores and gets the serve.
    const score = [...state.score];
    score[r] += 1;
    next = sideOut(state, score);
  } else if (config.players === "doubles" && state.serverNumber === 1) {
    // Rule 5.B.5: the serve passes to the partner (server 2).
    next = { ...state, serverNumber: 2, serverIsStarter: !state.serverIsStarter };
  } else {
    // Rule 5.A.3 / 5.B.6: side out.
    next = sideOut(state, [...state.score]);
  }

  next.rallies = state.rallies + 1;
  next.winner = winnerOf(next.score, config);
  return next;
}

// Replay a list of results ("W"/"L" string or array of booleans) from the start.
export function replay(config, results) {
  let state = newGame(config);
  for (const r of results) {
    if (r === "W" || r === true) state = playRally(state, true);
    else if (r === "L" || r === false) state = playRally(state, false);
    else throw new Error(`bad rally result: ${r}`);
  }
  return state;
}

// The score call to say before serving, e.g. "4-2-1" (doubles side-out) or "4-2".
export function scoreCall(state) {
  const s = state.score[state.serving];
  const r = state.score[1 - state.serving];
  return state.serverNumber === null ? `${s}-${r}` : `${s}-${r}-${state.serverNumber}`;
}

// Which half of the court the server serves from: "right" or "left".
export function serveSide(state) {
  const even = state.score[state.serving] % 2 === 0;
  if (state.config.players === "singles") return even ? "right" : "left"; // Rule 5.A.1
  // Rule 5.B.3: starter is right on even, partner is right on odd.
  return even === state.serverIsStarter ? "right" : "left";
}

// Undo-friendly game record: config + results string.
export function createMatch(config = {}) {
  return { config: normalizeConfig(config), results: "" };
}

export function matchState(match) {
  return replay(match.config, match.results);
}

export function recordRally(match, servingSideWon) {
  if (matchState(match).winner !== null) return match;
  return { ...match, results: match.results + (servingSideWon ? "W" : "L") };
}

export function undoRally(match) {
  return { ...match, results: match.results.slice(0, -1) };
}

export function canUndo(match) {
  return match.results.length > 0;
}
