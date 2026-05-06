type separatorType =
  | Top
  | Bottom
  | TitleTop
  | TitleBottom
  | Middle

let getCorners = (sepType, theme) =>
  switch sepType {
  | Bottom => (
      theme.AsciiGridTheme.lowerLeft,
      theme.AsciiGridTheme.lowerRight,
      theme.AsciiGridTheme.intersectionBottom,
    )
  | TitleBottom | Middle => (
      theme.AsciiGridTheme.intersectionLeft,
      theme.AsciiGridTheme.intersectionRight,
      theme.AsciiGridTheme.intersection,
    )
  | Top | TitleTop => (
      theme.AsciiGridTheme.upperLeft,
      theme.AsciiGridTheme.upperRight,
      theme.AsciiGridTheme.intersectionTop,
    )
  }

let totalInnerWidth = (colWidths, padding) =>
  Array.reduce(colWidths, 0, (sum, width) => sum + width + padding * 2)

let createSeparator = (colWidths, sepType, theme, padding) => {
  let (leftCorner, rightCorner, between) = getCorners(sepType, theme)
  let len = colWidths->Array.length

  if sepType == TitleTop {
    let inner =
      totalInnerWidth(colWidths, padding) + if len > 0 {
        len - 1
      } else {
        0
      }
    leftCorner ++ theme.AsciiGridTheme.line->String.repeat(inner) ++ rightCorner
  } else {
    let rec loop = (i, acc) =>
      if i >= len {
        acc ++ rightCorner
      } else {
        let width = switch colWidths[i] {
        | Some(w) => w
        | None => 0
        }
        let segment = acc ++ theme.AsciiGridTheme.line->String.repeat(width + padding * 2)
        let accNext = if i < len - 1 {
          segment ++ between
        } else {
          segment
        }
        loop(i + 1, accNext)
      }

    loop(0, leftCorner)
  }
}

let isNumeric = (s: string): bool => {
  let text = s->String.trim
  if Float.isFinite(text->Float.parseFloat) {
    true
  } else {
    let date = text->Date.fromString
    if !Float.isNaN(date->Date.getTime) {
      true
    } else {
      text->String.toLowerCase == "null"
    }
  }
}

let renderCell = (value: string, colWidth: int, padding: int, align: bool): string => {
  let pad = " "->String.repeat(padding)
  let targetLen = colWidth + padding * 2
  let safeLen = if targetLen >= 0 {
    targetLen
  } else {
    0
  }

  if align && isNumeric(value) {
    let leftSpaces = safeLen - value->String.length - padding
    let sanitized = if leftSpaces > 0 {
      leftSpaces
    } else {
      0
    }
    " "->String.repeat(sanitized) ++ value ++ pad
  } else {
    let rightSpaces = safeLen - value->String.length - padding
    let sanitized = if rightSpaces > 0 {
      rightSpaces
    } else {
      0
    }
    pad ++ value ++ " "->String.repeat(sanitized)
  }
}

let renderRow = (
  row: array<string>,
  colWidths: array<int>,
  theme: AsciiGridTheme.t,
  padding: int,
  align: bool,
): string => {
  let cells = row->Array.mapWithIndex((cell, idx) => {
    let width = switch colWidths[idx] {
    | Some(w) => w
    | None => 0
    }
    renderCell(cell, width, padding, align)
  })
  theme.AsciiGridTheme.wall ++
  cells->Array.reduce("", (acc, cell) =>
    if acc == "" {
      cell
    } else {
      acc ++ theme.AsciiGridTheme.wall ++ cell
    }
  ) ++
  theme.AsciiGridTheme.wall
}

let buildTitleLine = (title: string, availableWidth: int, theme: AsciiGridTheme.t): string => {
  let titleLen = title->String.length
  let totalPadding = availableWidth - titleLen
  let leftPad = " "->String.repeat(totalPadding / 2)
  let rightPad = " "->String.repeat(totalPadding - totalPadding / 2)
  theme.AsciiGridTheme.wall ++ leftPad ++ title ++ rightPad ++ theme.AsciiGridTheme.wall
}
