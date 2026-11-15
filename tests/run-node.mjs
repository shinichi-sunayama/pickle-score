// Run the tests with Node: node tests/run-node.mjs
import { readFileSync } from "node:fs";
import { runAll } from "./core.test.js";

const data = JSON.parse(readFileSync(new URL("./cases.json", import.meta.url), "utf8"));
const results = runAll(data);
for (const r of results) console.log(`${r.ok ? "ok  " : "FAIL"} ${r.name}${r.ok ? "" : `\n     ${r.error}`}`);
const failed = results.filter((r) => !r.ok).length;
console.log(`\n${results.length - failed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
