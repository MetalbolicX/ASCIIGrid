/**
 * Options module for ASCIIGrid.
 *
 * @module AsciiGridOptions
 */

type t = {
  title: option<string>,
  padding: int,
  header: bool,
  spreadsheet: bool,
  align: bool,
  theme: AsciiGridTheme.t,
}

let defaults: t
