// Game history: pure functions over a plain array (newest first), so they are easy to test and port.
// A record keeps the config and the rally results string, so any game can be replayed rally by rally.
import { replay, scoreCall, serveSide } from "./core.js";

export const HISTORY_LIMIT = 30;

// Build a history record from a match ({ id, config, results }). now = milliseconds since 1970.
export function recordFromMatch(match, now) {
  const s = replay(match.config, match.results);
  return {
    id: match.id,
    endedAt: now,
    config: match.config,
    results: match.results,
    score: [...s.score],
    winner: s.winner,
    rallies: s.rallies,
  };
}

// Add or replace (same id) a record at the top, keeping at most `limit` records.
export function upsertHistory(list, record, limit = HISTORY_LIMIT) {
  return [record, ...list.filter((r) => r.id !== record.id)].slice(0, limit);
}

export function removeFromHistory(list, id) {
  return list.filter((r) => r.id !== id);
}

// Rally-by-rally view of a game: what was called before each rally and what happened.
// Returns [{ n, call, side, serving, result }] where result is "W"/"L" (null for the state after the last rally).
export function timeline(config, results) {
  const rows = [];
  for (let i = 0; i <= results.length; i++) {
    const s = replay(config, results.slice(0, i));
    rows.push({
      n: i + 1,
      call: scoreCall(s),
      side: serveSide(s),
      serving: s.serving,
      winner: s.winner,
      result: i < results.length ? results[i] : null,
    });
  }
  return rows;
}

// Keep only well-formed records (data read back from storage may be old or damaged).
export function sanitizeHistory(list) {
  if (!Array.isArray(list)) return [];
  return list.filter((r) => r && typeof r.id === "string" && typeof r.results === "string"
    && /^[WL]*$/.test(r.results) && r.config && typeof r.endedAt === "number").slice(0, HISTORY_LIMIT);
}
