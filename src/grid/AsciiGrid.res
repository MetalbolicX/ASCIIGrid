/**
 * AsciiGrid core module.
 *
 * Renders a 2D array of strings as an ASCII table with configurable
 * themes, padding, alignment, title, and spreadsheet-style row/column labels.
 *
 * Ported from js-ascii-table.js by Akis Manolis (MIT license).
 * @module AsciiGrid
 */

type separatorType =
  | Top
  | Bottom
  | TitleTop
  | TitleBottom
  | Middle

type data = array<array<string>>

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

let isNumeric = (s: string): bool => {
  let parsed = s->Float.parseFloat
  if Float.isFinite(parsed) {
    true
  } else {
    let date = s->Date.fromString
    let ms = date->Date.getTime
    if !Float.isNaN(ms) {
      true
    } else {
      s->String.toLowerCase == "null"
    }
  }
}

let createSeparator = (colLengths: array<int>, sepType: separatorType, theme: AsciiGridTheme.t, padding: int): string => {
  let leftCorner = switch sepType {
  | Top | TitleTop => theme.AsciiGridTheme.upperLeft
  | Bottom => theme.AsciiGridTheme.lowerLeft
  | TitleBottom | Middle => theme.AsciiGridTheme.intersectionLeft
  }
  let rightCorner = switch sepType {
  | Top | TitleTop => theme.AsciiGridTheme.upperRight
  | Bottom => theme.AsciiGridTheme.lowerRight
  | TitleBottom | Middle => theme.AsciiGridTheme.intersectionRight
  }
  let intersectionBetween = switch sepType {
  | Top => theme.AsciiGridTheme.intersectionTop
  | TitleTop => theme.AsciiGridTheme.line
  | Bottom => theme.AsciiGridTheme.intersectionBottom
  | TitleBottom | Middle => theme.AsciiGridTheme.intersection
  }

  let lineSegment = theme.AsciiGridTheme.line->String.repeat(padding * 2 + 1)
  let len = colLengths->Belt.Array.length

  let rec loop = (i: int, acc: string): string => {
    if i >= len {
      acc ++ rightCorner
    } else {
      let colLen = switch Belt.Array.get(colLengths, i) {
      | Some(l) => l
      | None => 0
      }
      let segment = acc ++ theme.AsciiGridTheme.line->String.repeat(colLen) ++ lineSegment
      if i < len - 1 {
        loop(i + 1, segment ++ intersectionBetween)
      } else {
        loop(i + 1, segment)
      }
    }
  }

  loop(0, leftCorner)
}

let convertSpreadsheet = (table: array<array<string>>, header: bool): array<array<string>> => {
  let colCount = switch Belt.Array.get(table, 0) {
  | Some(firstRow) => firstRow->Belt.Array.length
  | None => 0
  }

  let spreadrow = Belt.Array.make(colCount, "")
  for i in 0 to colCount - 1 {
    let ch = switch String.get("ABCDEFGHIJKLMNOPQRSTUVWXYZ", i) {
    | Some(c) => c
    | None => ""
    }
    spreadrow[i] = ch
  }

  let tableWithSpreadrow = [spreadrow, ...table]

  tableWithSpreadrow->Belt.Array.mapWithIndex((i, row) => {
    let char = if header {
      if i > 1 { Int.toString(i - 1) } else { " " }
    } else {
      if i > 0 { Int.toString(i) } else { " " }
    }
    [char, ...row]
  })
}

let validateData = (data: data): option<string> => {
  switch Belt.Array.get(data, 0) {
  | None => None
  | Some(firstRow) => {
      let colCount = firstRow->Belt.Array.length
      let valid = data->Belt.Array.every(row => row->Belt.Array.length == colCount)
      if !valid { Some("Uneven number of columns") } else { None }
    }
  }
}

let validateTitle = (title: option<string>, colLengths: array<int>, theme: AsciiGridTheme.t, padding: int): option<string> => {
  switch title {
  | None => None
  | Some(t) => {
      let separatorLen = createSeparator(colLengths, Top, theme, padding)->String.length
      let availableWidth = separatorLen - 2
      if t->String.length > availableWidth { Some("Title is too large") } else { None }
    }
  }
}

let render = (data: data, options: AsciiGridOptions.t): result<string, string> => {
  let theme = options.AsciiGridOptions.theme
  let padding = options.AsciiGridOptions.padding

  switch validateData(data) {
  | Some(msg) => Error(msg)
  | None => {
      let processedData = if options.AsciiGridOptions.spreadsheet {
        convertSpreadsheet(data, options.AsciiGridOptions.header)
      } else {
        data
      }

      let colLengths = switch Belt.Array.get(processedData, 0) {
      | None => []
      | Some(firstRow) => {
          let colCount = firstRow->Belt.Array.length
          let lengths = Belt.Array.make(colCount, 0)
          for i in 0 to processedData->Belt.Array.length - 1 {
            for j in 0 to colCount - 1 {
              let cell = switch Belt.Array.get(processedData, i) {
              | None => ""
              | Some(row) => switch Belt.Array.get(row, j) {
                  | Some(c) => c
                  | None => ""
                }
              }
              let cellLen = cell->String.length
              let currentLen = switch Belt.Array.get(lengths, j) {
              | Some(l) => l
              | None => 0
              }
              if cellLen > currentLen {
                lengths[j] = cellLen
              }
            }
          }
          if options.AsciiGridOptions.header {
            for j in 0 to colCount - 1 {
              let headerCell = switch Belt.Array.get(firstRow, j) {
              | Some(c) => c
              | None => ""
              }
              let headerLen = headerCell->String.length
              let currentLen = switch Belt.Array.get(lengths, j) {
              | Some(l) => l
              | None => 0
              }
              if headerLen > currentLen {
                lengths[j] = headerLen
              }
            }
          }
          lengths
        }
      }

      switch validateTitle(options.AsciiGridOptions.title, colLengths, theme, padding) {
      | Some(msg) => Error(msg)
      | None => {
          let allLines: array<string> = []

          let topSepType = switch options.AsciiGridOptions.title {
          | Some(_) => TitleTop
          | None => Top
          }
          let topSep = createSeparator(colLengths, topSepType, theme, padding)
          allLines->Belt.Array.push(topSep)

          switch options.AsciiGridOptions.title {
          | None => ()
          | Some(title) => {
              let separatorLen = topSep->String.length
              let rem = separatorLen - 2 - title->String.length
              let half = rem / 2
              let row = " "->String.repeat(half) ++ title ++ " "->String.repeat(rem - half)
              let titleRow = theme.AsciiGridTheme.wall ++ row ++ theme.AsciiGridTheme.wall
              allLines->Belt.Array.push(titleRow)
              let titleBottom = createSeparator(colLengths, TitleBottom, theme, padding)
              allLines->Belt.Array.push(titleBottom)
            }
          }

          for i in 0 to processedData->Belt.Array.length - 1 {
            let row = switch Belt.Array.get(processedData, i) {
            | Some(r) => r
            | None => []
            }

            let cells = row->Belt.Array.mapWithIndex((j, cell) => {
              let colLen = switch Belt.Array.get(colLengths, j) {
              | Some(l) => l
              | None => 0
              }
              let leftPad = " "->String.repeat(padding)
              let cellLen = cell->String.length

              let alignedCell = if options.AsciiGridOptions.align && isNumeric(cell) {
                let extra = colLen - cellLen
                if extra > 0 {
                  " "->String.repeat(extra) ++ cell
                } else {
                  cell
                }
              } else {
                cell
              }

              let rightPadNeeded = colLen - alignedCell->String.length
              let rightPadExtra = if rightPadNeeded > 0 { rightPadNeeded - padding } else { 0 }
              let rightPad = " "->String.repeat(padding + rightPadExtra)

              leftPad ++ alignedCell ++ rightPad
            })

            let cellStr = cells->Belt.Array.reduce("", (acc, cell) =>
              if acc == "" { cell } else { acc ++ theme.AsciiGridTheme.wall ++ cell }
            )
            allLines->Belt.Array.push(theme.AsciiGridTheme.wall ++ cellStr ++ theme.AsciiGridTheme.wall)

            if !options.AsciiGridOptions.spreadsheet && options.AsciiGridOptions.header && i == 0 {
              allLines->Belt.Array.push(createSeparator(colLengths, Middle, theme, padding))
            } else if options.AsciiGridOptions.spreadsheet {
              if i == 0 {
                allLines->Belt.Array.push(createSeparator(colLengths, Middle, theme, padding))
              }
              if options.AsciiGridOptions.header && i == 1 {
                allLines->Belt.Array.push(createSeparator(colLengths, Middle, theme, padding))
              }
            }
          }

          allLines->Belt.Array.push(createSeparator(colLengths, Bottom, theme, padding))

          let table = allLines->Belt.Array.reduce("", (acc, line) =>
            if acc == "" { line } else { acc ++ "\n" ++ line }
          )
          Ok(table)
        }
      }
    }
  }
}