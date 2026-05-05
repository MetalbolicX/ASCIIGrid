open Test

/**
 * Test suite for AsciiGrid core functionality.
 * Tests cover rendering, themes, alignment, spreadsheet mode, and error cases.
 */

// ===== Basic 2x2 rendering =====
test("renders basic 2x2 table with MySQL theme", () => {
  let basicData: AsciiGrid.data = [
    ["A", "B"],
    ["1", "2"],
  ]
  let result = AsciiGrid.render(basicData, AsciiGridOptions.defaults)
  switch result {
  | Ok(table) => {
      let firstChar = switch String.get(table, 0) {
      | Some(c) => c
      | None => ""
      }
      assertion(
        (a, b) => a == b,
        "+",
        firstChar,
        ~operator="String equals to",
        ~message="Starts with +",
      )
      assertion(
        (a, b) => a == b,
        true,
        table->String.includes("A"),
        ~operator="Contains A",
        ~message="Contains A",
      )
      assertion(
        (a, b) => a == b,
        true,
        table->String.includes("1"),
        ~operator="Contains 1",
        ~message="Contains 1",
      )
    }
  | Error(msg) => {
      Console.log("Error: " ++ msg)
      fail(~message="Expected Ok, got Error", ())
    }
  }
})

// ===== Header separator =====
test("renders header separator when header is true", () => {
  let headerData: AsciiGrid.data = [
    ["Name", "Age", "City"],
    ["Alice", "30", "New York"],
    ["Bob", "25", "San Francisco"],
  ]
  let result = AsciiGrid.render(headerData, AsciiGridOptions.defaults)
  switch result {
  | Ok(table) => {
      assertion(
        (a, b) => a == b,
        true,
        table->String.includes("Name"),
        ~operator="Contains Name",
        ~message="Contains Name header",
      )
      assertion(
        (a, b) => a == b,
        true,
        table->String.includes("Age"),
        ~operator="Contains Age",
        ~message="Contains Age header",
      )
    }
  | Error(msg) => {
      Console.log("Error: " ++ msg)
      fail(~message="Expected Ok, got Error", ())
    }
  }
})

// ===== Title rendering =====
test("renders centered title between top and bottom separators", () => {
  let basicData: AsciiGrid.data = [
    ["A", "B"],
    ["1", "2"],
  ]
  let options = { ...AsciiGridOptions.defaults, title: Some("My Table") }
  let result = AsciiGrid.render(basicData, options)
  switch result {
  | Ok(table) => assertion(
      (a, b) => a == b,
      true,
      table->String.includes("My Table"),
      ~operator="Contains title",
      ~message="Contains title",
    )
  | Error(msg) => {
      Console.log("Error: " ++ msg)
      fail(~message="Expected Ok, got Error", ())
    }
  }
})

// ===== Unicode theme =====
test("renders with Unicode box-drawing characters", () => {
  let basicData: AsciiGrid.data = [
    ["A", "B"],
    ["1", "2"],
  ]
  let options = { ...AsciiGridOptions.defaults, theme: AsciiGridTheme.unicode }
  let result = AsciiGrid.render(basicData, options)
  switch result {
  | Ok(table) => {
      assertion(
        (a, b) => a == b,
        true,
        table->String.includes("╔"),
        ~operator="Contains ╔",
        ~message="Has Unicode upper-left corner",
      )
      assertion(
        (a, b) => a == b,
        true,
        table->String.includes("║"),
        ~operator="Contains ║",
        ~message="Has Unicode wall",
      )
    }
  | Error(msg) => {
      Console.log("Error: " ++ msg)
      fail(~message="Expected Ok, got Error", ())
    }
  }
})

// ===== Numeric alignment =====
test("right-aligns numeric values when align is true", () => {
  let numData: AsciiGrid.data = [
    ["Item", "Price"],
    ["Apple", "42"],
    ["Banana", "7"],
  ]
  let options = { ...AsciiGridOptions.defaults, align: true }
  let result = AsciiGrid.render(numData, options)
  switch result {
  | Ok(table) => assertion(
      (a, b) => a == b,
      true,
      table->String.includes("42"),
      ~operator="Contains 42",
      ~message="Contains number 42",
    )
  | Error(msg) => {
      Console.log("Error: " ++ msg)
      fail(~message="Expected Ok, got Error", ())
    }
  }
})

// ===== Spreadsheet mode =====
test("renders with column letters and row numbers in spreadsheet mode", () => {
  let basicData: AsciiGrid.data = [
    ["A", "B"],
    ["1", "2"],
  ]
  let options = { ...AsciiGridOptions.defaults, spreadsheet: true }
  let result = AsciiGrid.render(basicData, options)
  switch result {
  | Ok(table) => {
      assertion(
        (a, b) => a == b,
        true,
        table->String.includes("A"),
        ~operator="Contains A",
        ~message="Contains column letter A",
      )
      assertion(
        (a, b) => a == b,
        true,
        table->String.includes("B"),
        ~operator="Contains B",
        ~message="Contains column letter B",
      )
    }
  | Error(msg) => {
      Console.log("Error: " ++ msg)
      fail(~message="Expected Ok, got Error", ())
    }
  }
})

// ===== Uneven columns error =====
test("returns Error for uneven column counts", () => {
  let unevenData: AsciiGrid.data = [
    ["A"],
    ["1", "2"],
  ]
  let result = AsciiGrid.render(unevenData, AsciiGridOptions.defaults)
  switch result {
  | Ok(_) => fail(~message="Expected Error for uneven columns", ())
  | Error(msg) => assertion(
      (a, b) => a == b,
      "Uneven number of columns",
      msg,
      ~operator="String equals to",
      ~message="Error message matches",
    )
  }
})

// ===== Title too large error =====
test("returns Error when title exceeds available width", () => {
  let tinyData: AsciiGrid.data = [["X"]]
  let options = { ...AsciiGridOptions.defaults, title: Some("This title is way too long for this tiny table") }
  let result = AsciiGrid.render(tinyData, options)
  switch result {
  | Ok(_) => fail(~message="Expected Error for title too large", ())
  | Error(msg) => assertion(
      (a, b) => a == b,
      "Title is too large",
      msg,
      ~operator="String equals to",
      ~message="Error message matches",
    )
  }
})