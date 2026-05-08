open Test

let assertStringEqual = (expected: string, actual: string, message: string) =>
  assertion((a, b) => a == b, expected, actual, ~operator="String equals to", ~message)

let assertContains = (text: string, needle: string, message: string) =>
  assertion((a, b) => a == b, true, text->String.includes(needle), ~operator="Contains", ~message)

let matrix = [["Name", "Age", "City"], ["Alice", "30", "NYC"], ["Bob", "25", "LA"]]

let expectedBasic =
  "+-----+----+\n" ++ "| a   | bb |\n" ++ "+-----+----+\n" ++ "| ccc | d  |\n" ++ "+-----+----+"

let expectedTitle =
  "+--------------------+\n" ++
  "|       Users        |\n" ++
  "+-------+-----+------+\n" ++
  "| Name  | Age | City |\n" ++
  "+-------+-----+------+\n" ++
  "| Alice | 30  | NYC  |\n" ++
  "| Bob   | 25  | LA   |\n" ++ "+-------+-----+------+"

let expectedSpreadsheetHeader =
  "+---+-------+-----+------+\n" ++
  "|   | A     | B   | C    |\n" ++
  "+---+-------+-----+------+\n" ++
  "| 0 | Name  | Age | City |\n" ++
  "+---+-------+-----+------+\n" ++
  "| 1 | Alice | 30  | NYC  |\n" ++
  "| 2 | Bob   | 25  | LA   |\n" ++ "+---+-------+-----+------+"

let expectedSpreadsheetNoHeader =
  "+---+-------+-----+------+\n" ++
  "| 1 | A     | B   | C    |\n" ++
  "+---+-------+-----+------+\n" ++
  "| 2 | Name  | Age | City |\n" ++
  "| 3 | Alice | 30  | NYC  |\n" ++
  "| 4 | Bob   | 25  | LA   |\n" ++ "+---+-------+-----+------+"

let expectedNumericAlignment =
  "+--------+-------+\n" ++
  "| Item   | Price |\n" ++
  "+--------+-------+\n" ++
  "| Apple  |    42 |\n" ++
  "| Banana |     7 |\n" ++ "+--------+-------+"

let createRowObject = arr => Dict.fromArray(arr)

test("renders basic matrix output", () => {
  let data = [["a", "bb"], ["ccc", "d"]]
  switch AsciiGrid.render(data, AsciiGridOptions.defaults) {
  | Ok(table) => assertStringEqual(expectedBasic, table, "basic matrix must match reference")
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("renders title block", () => {
  switch AsciiGrid.render(matrix, {...AsciiGridOptions.defaults, title: Some("Users")}) {
  | Ok(table) => assertStringEqual(expectedTitle, table, "title block must match reference")
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("renders spreadsheet mode with header", () => {
  switch AsciiGrid.render(matrix, {...AsciiGridOptions.defaults, spreadsheet: true, header: true}) {
  | Ok(table) =>
    assertStringEqual(expectedSpreadsheetHeader, table, "spreadsheet+header must match")
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("renders spreadsheet mode without header", () => {
  switch AsciiGrid.render(
    matrix,
    {...AsciiGridOptions.defaults, spreadsheet: true, header: false},
  ) {
  | Ok(table) =>
    assertStringEqual(expectedSpreadsheetNoHeader, table, "spreadsheet-no-header must match")
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("aligns numeric cells", () => {
  let data = [["Item", "Price"], ["Apple", "42"], ["Banana", "7"]]
  switch AsciiGrid.render(data, {...AsciiGridOptions.defaults, align: true}) {
  | Ok(table) =>
    assertStringEqual(expectedNumericAlignment, table, "numeric alignment must match reference")
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("renders from row objects", () => {
  let rows = [
    createRowObject([("name", "Alice"), ("age", "30"), ("city", "NYC")]),
    createRowObject([("name", "Bob"), ("age", "25")]),
  ]
  switch AsciiGrid.renderWithObjects(rows, AsciiGridOptions.defaults) {
  | Ok(table) => {
      assertContains(table, "Alice", "includes Alice")
      assertContains(table, "Bob", "includes Bob")
      assertContains(table, "city", "includes city column")
    }
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("returns Error for uneven columns", () => {
  let data = [["A"], ["1", "2"]]
  switch AsciiGrid.render(data, AsciiGridOptions.defaults) {
  | Ok(_) => fail(~message="Expected Error for uneven columns", ())
  | Error(msg) => assertStringEqual("Uneven number of columns", msg, "error must match")
  }
})

test("returns Error when title too long", () => {
  switch AsciiGrid.render(
    [["X"]],
    {...AsciiGridOptions.defaults, title: Some("This title is way too long for this tiny table")},
  ) {
  | Ok(_) => fail(~message="Expected Error for title too large", ())
  | Error(msg) => assertStringEqual("Title is too large", msg, "error must match")
  }
})

test("renders with unicode theme", () => {
  switch AsciiGrid.render(matrix, {...AsciiGridOptions.defaults, theme: AsciiGridTheme.unicode}) {
  | Ok(table) => {
      assertContains(table, "╔", "has upper-left corner")
      assertContains(table, "║", "has vertical wall")
      assertContains(table, "╚", "has lower-left corner")
    }
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("applies padding 2", () => {
  switch AsciiGrid.render(matrix, {...AsciiGridOptions.defaults, padding: 2}) {
  | Ok(table) => assertContains(table, "  Name", "Name has double left padding")
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("handles empty title string", () => {
  switch AsciiGrid.render(matrix, {...AsciiGridOptions.defaults, title: Some("")}) {
  | Ok(table) => {
      let firstLine = table->String.split("\n")->Array.get(0)->Option.getOr("")
      assertion(
        (a, b) => a == b,
        true,
        firstLine->String.startsWith("+"),
        ~operator="equals",
        ~message="first line starts with +",
      )
    }
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("handles single row", () => {
  switch AsciiGrid.render([["Header"]], AsciiGridOptions.defaults) {
  | Ok(table) => {
      assertContains(table, "Header", "contains header text")
      let lines = table->String.split("\n")
      let allValid = lines->Array.every(l => l->String.startsWith("+") || l->String.startsWith("|"))
      assertion(
        (a, b) => a == b,
        true,
        allValid,
        ~operator="equals",
        ~message="all lines start with + or |",
      )
    }
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("handles single column", () => {
  switch AsciiGrid.render([["a"], ["b"], ["c"]], AsciiGridOptions.defaults) {
  | Ok(table) => {
      let wallLines = table->String.split("\n")->Array.filter(l => l->String.startsWith("|"))
      wallLines->Array.forEach(l =>
        assertion(
          (a, b) => a == b,
          3,
          l->String.split("|")->Array.length,
          ~operator="equals",
          ~message="single column: 3 parts per wall line",
        )
      )
    }
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("null CellNull values render as empty strings", () => {
  let rows: array<AsciiGridAdapters.richRowObject> = [
    Dict.fromArray([
      ("a", AsciiGridAdapters.CellNull),
      ("b", AsciiGridAdapters.CellNull),
      ("c", AsciiGridAdapters.CellString("x")),
    ]),
  ]
  switch AsciiGrid.renderWithRichObjects(rows, AsciiGridOptions.defaults) {
  | Ok(table) => {
      let dataLine = table->String.split("\n")->Array.get(3)->Option.getOr("")
      assertStringEqual("|   |   | x |", dataLine, "null cells render as empty strings")
    }
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("CellBool values are stringified", () => {
  let data: array<array<AsciiGridAdapters.cellValue>> = [
    [AsciiGridAdapters.CellString("flag")],
    [AsciiGridAdapters.CellBool(true)],
    [AsciiGridAdapters.CellBool(false)],
  ]
  switch AsciiGrid.renderRich(data, AsciiGridOptions.defaults) {
  | Ok(table) => {
      assertContains(table, "true", "contains true")
      assertContains(table, "false", "contains false")
    }
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("CellInt and CellFloat are stringified and right-aligned", () => {
  let data: array<array<AsciiGridAdapters.cellValue>> = [
    [AsciiGridAdapters.CellString("label"), AsciiGridAdapters.CellString("value")],
    [AsciiGridAdapters.CellString("A"), AsciiGridAdapters.CellInt(1)],
    [AsciiGridAdapters.CellString("B"), AsciiGridAdapters.CellFloat(22.5)],
    [AsciiGridAdapters.CellString("C"), AsciiGridAdapters.CellInt(-3)],
  ]
  switch AsciiGrid.renderRich(data, {...AsciiGridOptions.defaults, align: true}) {
  | Ok(table) => {
      assertContains(table, "1", "contains 1")
      assertContains(table, "22.5", "contains 22.5")
      assertContains(table, "-3", "contains -3")
    }
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})
