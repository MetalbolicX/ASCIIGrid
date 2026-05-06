open Test

let assertStringEqual = (expected: string, actual: string, message: string) =>
  assertion((a, b) => a == b, expected, actual, ~operator="String equals to", ~message)

let assertContains = (text: string, needle: string, message: string) =>
  assertion((a, b) => a == b, true, text->String.includes(needle), ~operator="Contains", ~message)

let matrix = [
  ["Name", "Age", "City"],
  ["Alice", "30", "NYC"],
  ["Bob", "25", "LA"],
]

let expectedBasic =
  "+-----+----+\n"
  ++ "| a   | bb |\n"
  ++ "+-----+----+\n"
  ++ "| ccc | d  |\n"
  ++ "+-----+----+"

let expectedTitle =
  "+--------------------+\n"
  ++ "|       Users        |\n"
  ++ "+-------+-----+------+\n"
  ++ "| Name  | Age | City |\n"
  ++ "+-------+-----+------+\n"
  ++ "| Alice | 30  | NYC  |\n"
  ++ "| Bob   | 25  | LA   |\n"
  ++ "+-------+-----+------+"

let expectedSpreadsheetHeader =
  "+---+-------+-----+------+\n"
  ++ "|   | A     | B   | C    |\n"
  ++ "+---+-------+-----+------+\n"
  ++ "| 0 | Name  | Age | City |\n"
  ++ "+---+-------+-----+------+\n"
  ++ "| 1 | Alice | 30  | NYC  |\n"
  ++ "| 2 | Bob   | 25  | LA   |\n"
  ++ "+---+-------+-----+------+"

let expectedSpreadsheetNoHeader =
  "+---+-------+-----+------+\n"
  ++ "| 1 | A     | B   | C    |\n"
  ++ "+---+-------+-----+------+\n"
  ++ "| 2 | Name  | Age | City |\n"
  ++ "| 3 | Alice | 30  | NYC  |\n"
  ++ "| 4 | Bob   | 25  | LA   |\n"
  ++ "+---+-------+-----+------+"

let expectedNumericAlignment =
  "+--------+-------+\n"
  ++ "| Item   | Price |\n"
  ++ "+--------+-------+\n"
  ++ "| Apple  |    42 |\n"
  ++ "| Banana |     7 |\n"
  ++ "+--------+-------+"

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
  | Ok(table) => assertStringEqual(expectedSpreadsheetHeader, table, "spreadsheet+header must match")
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("renders spreadsheet mode without header", () => {
  switch AsciiGrid.render(matrix, {...AsciiGridOptions.defaults, spreadsheet: true, header: false}) {
  | Ok(table) => assertStringEqual(expectedSpreadsheetNoHeader, table, "spreadsheet-no-header must match")
  | Error(msg) => fail(~message="Expected Ok, got " ++ msg, ())
  }
})

test("aligns numeric cells", () => {
  let data = [["Item", "Price"], ["Apple", "42"], ["Banana", "7"]]
  switch AsciiGrid.render(data, {...AsciiGridOptions.defaults, align: true}) {
  | Ok(table) => assertStringEqual(expectedNumericAlignment, table, "numeric alignment must match reference")
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
  switch AsciiGrid.render([["X"]], {...AsciiGridOptions.defaults, title: Some("This title is way too long for this tiny table")}) {
  | Ok(_) => fail(~message="Expected Error for title too large", ())
  | Error(msg) => assertStringEqual("Title is too large", msg, "error must match")
  }
})
