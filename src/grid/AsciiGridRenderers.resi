type separatorType =
  | Top
  | Bottom
  | TitleTop
  | TitleBottom
  | Middle

let createSeparator: (array<int>, separatorType, AsciiGridTheme.t, int) => string
let isNumeric: string => bool
let renderRow: (array<string>, array<int>, AsciiGridTheme.t, int, bool) => string
let buildTitleLine: (string, int, AsciiGridTheme.t) => string
