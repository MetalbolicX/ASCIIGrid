/**
 * Options module for ASCIIGrid.
 *
 * Configures how the ASCII table is rendered:
 * title, padding, header visibility, spreadsheet mode, alignment, and theme.
 *
 * @module Options
 */
type t = {
  /** Optional table title displayed centered at the top. */
  title: option<string>,
  /** Number of spaces added on each side of a cell's content. Default: 1. */
  padding: int,
  /** Whether to show a separator line after the first row (header). Default: true. */
  header: bool,
  /** Whether to add column letters (A, B, C...) and row numbers. Default: false. */
  spreadsheet: bool,
  /** Whether to right-align numeric values. Default: false. */
  align: bool,
  /** The character theme used for box-drawing. Default: MySQL. */
  theme: AsciiGridTheme.t,
}

/** Default rendering options. */
let defaults: t = {
  title: None,
  padding: 1,
  header: true,
  spreadsheet: false,
  align: false,
  theme: AsciiGridTheme.mysql,
}
