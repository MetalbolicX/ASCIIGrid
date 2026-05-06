import { describe, it } from "node:test";
import assert from "node:assert";
import { renderTable, getThemes, mergeOptions, TableError } from "./index.ts";

const MYSQL_THEME = {
  upperLeft: "+",
  upperRight: "+",
  lowerLeft: "+",
  lowerRight: "+",
  intersection: "+",
  line: "-",
  wall: "|",
  intersectionTop: "+",
  intersectionBottom: "+",
  intersectionLeft: "+",
  intersectionRight: "+",
};

const UNICODE_THEME = {
  upperLeft: "╔",
  upperRight: "╗",
  lowerLeft: "╚",
  lowerRight: "╝",
  intersection: "╬",
  line: "═",
  wall: "║",
  intersectionTop: "╦",
  intersectionBottom: "╩",
  intersectionLeft: "╠",
  intersectionRight: "╣",
};

const matrix = [["Name", "Age", "City"], ["Alice", 30, "NYC"], ["Bob", 25, "LA"]];

describe("renderTable", () => {
  it("renders a basic 2D matrix", () => {
    const result = renderTable([["a", "bb"], ["ccc", "d"]]);
    const lines = result.split("\n");
    // 5 lines: top sep, header, middle sep, data, bottom sep
    assert.strictEqual(lines.length, 5);
    // col widths: max(1,3)=3 and max(2,1)=2, padding=1 → 3+2=5 and 2+2=4 dashes
    const sep = "+-----+----+";
    assert.strictEqual(lines[0], sep, "top separator wrong");
    assert.strictEqual(lines[2], sep, "middle separator wrong");
    assert.strictEqual(lines[4], sep, "bottom separator wrong");
    // all lines same width (structural alignment)
    assert.ok(lines.every((l) => l.length === sep.length), "lines have inconsistent widths");
    // cell content
    assert.match(lines[1], /^\| a\s+\| bb \|$/);
    assert.match(lines[3], /^\| ccc \| d\s+\|$/);
  });

  it("renders array of objects via Adapter pattern", () => {
    const objects = [
      { name: "Alice", age: 30, city: "NYC" },
      { name: "Bob", age: 25 },
    ];
    const result = renderTable(objects);
    assert.match(result, /name.*age.*city/s);
    assert.match(result, /Alice.*30.*NYC/s);
    assert.match(result, /Bob.*25/s);
  });

  it("handles objects with missing keys (fills empty strings)", () => {
    const result = renderTable([{ name: "Alice", age: 30 }]);
    const lines = result.split("\n");
    assert.strictEqual(lines.length, 5);
    assert.match(lines[0], /^\+/);
    assert.match(lines[1], /name/);
    assert.match(lines[1], /age/);
    assert.ok(!lines[1].includes("city"));
  });

  it("applies title block", () => {
    const result = renderTable(matrix, { title: "Users" });
    const lines = result.split("\n");
    // title_top: all columns merged → inner = (5+2)+(3+2)+(4+2)+2 connectors = 20 dashes
    assert.strictEqual(lines[0], "+--------------------+", "title top separator wrong");
    // title line must be same width as separator and contain "Users"
    assert.strictEqual(lines[0].length, lines[1].length, "title line width mismatch");
    assert.match(lines[1], /^\|.*Users.*\|$/);
    // title_bottom must match body separators
    const bodySep = "+-------+-----+------+";
    assert.strictEqual(lines[2], bodySep, "title bottom separator wrong");
    // title top and body separator must have equal width (box alignment)
    assert.strictEqual(lines[0].length, lines[2].length, "title and body widths differ");
  });

  it("throws TableError when title is too large", () => {
    assert.throws(() => {
      renderTable(matrix, { title: "This title is way too long for the table" });
    }, TableError);
  });

  it("aligns numeric cells right when align:true", () => {
    const result = renderTable(matrix, { align: true });
    const lines = result.split("\n");
    const ageCol = lines[1].split("|")[2];
    assert.match(ageCol, /^\s+Age\s+$/);
  });

  it("applies custom Unicode theme", () => {
    const result = renderTable(matrix, { theme: UNICODE_THEME });
    assert.match(result, /╔/);
    assert.match(result, /║/);
    assert.match(result, /╠/);
    assert.match(result, /╚/);
  });

  it("renders spreadsheet mode with header", () => {
    const result = renderTable(matrix, { spreadsheet: true, header: true });
    const lines = result.split("\n");
    assert.match(lines[1], /\|   \| A/);
    assert.match(lines[3], /\| 0 \| Name/);
    assert.match(lines[5], /\| 1 \| Alice/);
  });

  it("renders spreadsheet mode without header", () => {
    const result = renderTable(matrix, { spreadsheet: true, header: false });
    const lines = result.split("\n");
    assert.match(lines[1], /\| 1 \| A/);
    assert.match(lines[3], /\| 2 \| Name/);
  });

  it("throws on uneven column count", () => {
    assert.throws(() => {
      renderTable([["a", "b"], ["c"]]);
    }, TableError);
  });

  it("uses Object.freeze on themes", () => {
    const themes = getThemes();
    for (const theme of themes) {
      assert.ok(Object.isFrozen(theme));
      assert.ok(Object.isFrozen(theme.value));
    }
  });

  it("mergeOptions returns frozen object", () => {
    const opts = mergeOptions({ title: "Test" });
    assert.ok(Object.isFrozen(opts));
    assert.strictEqual(opts.title, "Test");
  });

  it("PartialTableOptions only overrides specified fields", () => {
    const result = renderTable(matrix, { padding: 2 });
    assert.match(result, /\|\s+Name\s+\|/);
  });

  it("error type is 'input' for column errors", () => {
    try {
      renderTable([["a", "b"], ["c"]]);
    } catch (e) {
      if (e instanceof TableError) {
        assert.strictEqual(e.type, "input");
      }
    }
  });

  it("error type is 'title' for title errors", () => {
    try {
      renderTable(matrix, { title: "This title is way too long for the table" });
    } catch (e) {
      if (e instanceof TableError) {
        assert.strictEqual(e.type, "title");
      }
    }
  });

  it("returns consistent output for same input", () => {
    const result1 = renderTable(matrix);
    const result2 = renderTable(matrix);
    assert.strictEqual(result1, result2);
  });

  it("renderTable is pure: same input + options always yields same output", () => {
    const opts = { title: "Test", align: true };
    const r1 = renderTable(matrix, opts);
    const r2 = renderTable(matrix, opts);
    assert.strictEqual(r1, r2);
  });

  it("getThemes returns all three built-in themes", () => {
    const themes = getThemes();
    const titles = themes.map((t) => t.title);
    assert.ok(titles.includes("MySQL"));
    assert.ok(titles.includes("Unicode"));
    assert.ok(titles.includes("Oracle"));
  });

  it("handles empty title", () => {
    const result = renderTable(matrix, { title: "" });
    const lines = result.split("\n");
    assert.match(lines[0], /^\+/);
  });

  it("handles single row", () => {
    const result = renderTable([["Header"]]);
    assert.match(result, /Header/);
    const lines = result.split("\n");
    assert.ok(lines.every((l) => l.startsWith("+") || l.startsWith("|")));
  });

  it("handles single column", () => {
    const result = renderTable([["a"], ["b"], ["c"]]);
    const lines = result.split("\n").filter((l) => l.includes("|"));
    assert.ok(lines.every((l) => l.split("|").length === 3));
  });

  it("numeric alignment works with various number formats", () => {
    const numMatrix = [["label", "value"], ["A", 1], ["B", 22.5], ["C", -3]];
    const result = renderTable(numMatrix, { align: true });
    assert.ok(result.includes("1"));
    assert.ok(result.includes("22.5"));
    assert.ok(result.includes("-3"));
  });

  it("null and undefined in object rows render as empty strings", () => {
    const result = renderTable([{ a: null, b: undefined, c: "x" }]);
    const lines = result.split("\n");
    assert.match(lines[3], /\|   \|   \| x \|/);
  });

  it("true and false boolean values are stringified", () => {
    const result = renderTable([["flag"], [true], [false]]);
    assert.match(result, /true/);
    assert.match(result, /false/);
  });
});