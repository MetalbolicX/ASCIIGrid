import { renderTable, mergeOptions, getThemeByName } from "../src/table-ts/index.ts";

const matrix = [
  ["Name", "Age", "City"],
  ["Alice", "30", "NYC"],
  ["Bob", "25", "LA"]
];

console.log("--- Simple matrix output ---");
console.log(renderTable(matrix));

const rows = [
  { name: "Alice", age: 30, city: "NYC" },
  { name: "Bob", age: 25 }
];

console.log("\n--- Adapter (array of objects) output ---");
console.log(renderTable(rows));

const data = [["Name", "Score"], ["Alice", 123], ["Bob", 99]];
const unicode = getThemeByName("Unicode");
const opts = mergeOptions({ title: "Leaderboard", spreadsheet: true, header: true, align: true, theme: unicode });

console.log("\n--- Spreadsheet + title + Unicode theme output ---");
console.log(renderTable(data, opts));
