let rec intToColumnLetter = (n: int): string => {
  let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  if n < 26 {
    switch String.get(alphabet, n) {
    | Some(ch) => ch
    | None => ""
    }
  } else {
    let quotient = n / 26
    let remainder = n - quotient * 26
    let prefix = intToColumnLetter(quotient - 1)
    let suffix = switch String.get(alphabet, remainder) {
    | Some(ch) => ch
    | None => ""
    }
    prefix ++ suffix
  }
}

let prependRowIndex = (rows: array<array<string>>, header: bool): array<array<string>> => {
  rows->Belt.Array.mapWithIndex((idx, row) => {
    let label = if header {
      if idx == 0 {
        " "
      } else {
        Int.toString(idx - 1)
      }
    } else {
      if idx == 0 {
        "1"
      } else {
        Int.toString(idx + 1)
      }
    }
    [label, ...row]
  })
}

let applySpreadsheetMode = (data: array<array<string>>, options: AsciiGridOptions.t): array<array<string>> => {
  if !options.AsciiGridOptions.spreadsheet {
    data
  } else {
    if data->Belt.Array.length == 0 {
      data
    } else {
      let colCount = data->Belt.Array.get(0)->Belt.Option.getWithDefault([])->Belt.Array.length
      let spreadsheetRow = Belt.Array.make(colCount, "")
      for i in 0 to colCount - 1 {
        spreadsheetRow[i] = intToColumnLetter(i)
      }
      let withHeader = [spreadsheetRow, ...data]
      prependRowIndex(withHeader, options.AsciiGridOptions.header)
    }
  }
}
