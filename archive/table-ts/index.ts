/**
 * ASCIIGrid — Pure functional ASCII table renderer.
 *
 * Public API: single named export `renderTable`.
 *
 * Usage:
 *   import { renderTable } from "./table-ts";
 *
 *   // 2D array
 *   const t1 = renderTable([["a", "b"], ["c", "d"]]);
 *
 *   // Array of objects
 *   const t2 = renderTable([
 *     { name: "Alice", age: 30 },
 *     { name: "Bob",   age: 25 },
 *   ]);
 */
export { renderTable } from "./pipeline";
export type {
  InputData,
  TableOptions,
  PartialTableOptions,
  TableData,
  ThemeValue,
  ThemeDefinition,
  BuiltInThemeName,
  CellValue,
  RowObject,
  ColumnWidths,
  SeparatorType,
  PipelineContext,
} from "./types";
export { THEMES, getThemes, getThemeByName, mergeOptions } from "./themes";
export { TableError, inputError, titleError } from "./errors";