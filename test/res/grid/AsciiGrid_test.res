open Test

let assertStringEqual = (expected: string, actual: string, message: string): unit =>
  assertion((a, b) => a == b, expected, actual, ~operator="String equals to", ~message=message)

let assertContains = (text: string, needle: string, message: string): unit =>
  assertion((a, b) => a == b, true, text->String.includes(needle), ~operator="Contains", ~message=message)

test("renders exact basic matrix output", () => {
  let data: AsciiGrid.data = [["a", "bb"], ["ccc", "d"]]
  let expected =
    "+-----+----+\n"
    ++ "| a   | bb |\n"
    ++ "+-----+----+\n"
    ++ "| ccc | d  |\n"
    ++ "+-----+----+"

  switch AsciiGrid.render(data, AsciiGridOptions.defaults) {
  | Ok(table) => assertStringEqual(expected, table, "basic matrix must match reference output")
  | Error(msg) => fail(~message="Expected Ok, got Error: " ++ msg, ())
  }
})

test("renders exact title block output", () => {
  let data: AsciiGrid.data = [["Name", "Age", "City"], ["Alice", "30", "NYC"], ["Bob", "25", "LA"]]
  let options = {...AsciiGridOptions.defaults, title: Some("Users")}
  let expected =
    "+--------------------+\n"
    ++ "|       Users        |\n"
    ++ "+-------+-----+------+\n"
    ++ "| Name  | Age | City |\n"
    ++ "+-------+-----+------+\n"
    ++ "| Alice | 30  | NYC  |\n"
    ++ "| Bob   | 25  | LA   |\n"
    ++ "+-------+-----+------+"

  switch AsciiGrid.render(data, options) {
  | Ok(table) => assertStringEqual(expected, table, "title rendering must match reference output")
  | Error(msg) => fail(~message="Expected Ok, got Error: " ++ msg, ())
  }
})

test("renders exact spreadsheet output with header", () => {
  let data: AsciiGrid.data = [["Name", "Age", "City"], ["Alice", "30", "NYC"], ["Bob", "25", "LA"]]
  let options = {...AsciiGridOptions.defaults, spreadsheet: true, header: true}
  let expected =
    "+---+-------+-----+------+\n"
    ++ "|   | A     | B   | C    |\n"
    ++ "+---+-------+-----+------+\n"
    ++ "| 0 | Name  | Age | City |\n"
    ++ "+---+-------+-----+------+\n"
    ++ "| 1 | Alice | 30  | NYC  |\n"
    ++ "| 2 | Bob   | 25  | LA   |\n"
    ++ "+---+-------+-----+------+"

  switch AsciiGrid.render(data, options) {
  | Ok(table) => assertStringEqual(expected, table, "spreadsheet with header must match reference output")
  | Error(msg) => fail(~message="Expected Ok, got Error: " ++ msg, ())
  }
})

test("renders exact spreadsheet output without header", () => {
  let data: AsciiGrid.data = [["Name", "Age", "City"], ["Alice", "30", "NYC"], ["Bob", "25", "LA"]]
  let options = {...AsciiGridOptions.defaults, spreadsheet: true, header: false}
  let expected =
    "+---+-------+-----+------+\n"
    ++ "| 1 | A     | B   | C    |\n"
    ++ "+---+-------+-----+------+\n"
    ++ "| 2 | Name  | Age | City |\n"
    ++ "| 3 | Alice | 30  | NYC  |\n"
    ++ "| 4 | Bob   | 25  | LA   |\n"
    ++ "+---+-------+-----+------+"

  switch AsciiGrid.render(data, options) {
  | Ok(table) => assertStringEqual(expected, table, "spreadsheet without header must match reference output")
  | Error(msg) => fail(~message="Expected Ok, got Error: " ++ msg, ())
  }
})

test("renders exact numeric alignment output", () => {
  let data: AsciiGrid.data = [["Item", "Price"], ["Apple", "42"], ["Banana", "7"]]
  let options = {...AsciiGridOptions.defaults, align: true}
  let expected =
    "+--------+-------+\n"
    ++ "| Item   | Price |\n"
    ++ "+--------+-------+\n"
    ++ "| Apple  |    42 |\n"
    ++ "| Banana |     7 |\n"
    ++ "+--------+-------+"

  switch AsciiGrid.render(data, options) {
  | Ok(table) => assertStringEqual(expected, table, "numeric alignment must match reference output")
  | Error(msg) => fail(~message="Expected Ok, got Error: " ++ msg, ())
  }
})

test("supports spreadsheet columns beyond Z", () => {
  let row = Belt.Array.makeBy(28, i => Int.toString(i))
  let data: AsciiGrid.data = [row]
  let options = {...AsciiGridOptions.defaults, spreadsheet: true, header: false}

  switch AsciiGrid.render(data, options) {
  | Ok(table) => {
      assertContains(table, "AA", "must contain AA column label")
      assertContains(table, "AB", "must contain AB column label")
    }
  | Error(msg) => fail(~message="Expected Ok, got Error: " ++ msg, ())
  }
})

test("returns Error for uneven column counts", () => {
  let unevenData: AsciiGrid.data = [["A"], ["1", "2"]]
  switch AsciiGrid.render(unevenData, AsciiGridOptions.defaults) {
  | Ok(_) => fail(~message="Expected Error for uneven columns", ())
  | Error(msg) => assertStringEqual("Uneven number of columns", msg, "error message must match")
  }
})

test("returns Error when title exceeds available width", () => {
  let tinyData: AsciiGrid.data = [["X"]]
  let options = {...AsciiGridOptions.defaults, title: Some("This title is way too long for this tiny table")}

  switch AsciiGrid.render(tinyData, options) {
  | Ok(_) => fail(~message="Expected Error for title too large", ())
  | Error(msg) => assertStringEqual("Title is too large", msg, "error message must match")
  }
})

test("renders with Unicode theme", () => {
  let basicData: AsciiGrid.data = [["A", "B"], ["1", "2"]]
  let options = {...AsciiGridOptions.defaults, theme: AsciiGridTheme.unicode}

  switch AsciiGrid.render(basicData, options) {
  | Ok(table) => {
      assertContains(table, "╔", "must contain unicode upper-left corner")
      assertContains(table, "║", "must contain unicode wall")
      assertContains(table, "╚", "must contain unicode lower-left corner")
    }
  | Error(msg) => fail(~message="Expected Ok, got Error: " ++ msg, ())
  }
})
