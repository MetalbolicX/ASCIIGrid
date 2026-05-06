/**
 * Layout Calculator — validates data shape and computes column widths.
 *
 * Pure functions only: input TableData + options, output is
 * a tuple of [validated TableData, ColumnWidths].
 */
import type { TableData, ColumnWidths, TableOptions } from "./types";
import { inputError } from "./errors";

export const validateShape = (data: TableData): void => {
  if (data.length === 0) return;
  const firstLen = data[0].length;
  for (let i = 0; i < data.length; i++) {
    if (data[i].length !== firstLen) {
      inputError("Uneven number of columns");
    }
  }
};

export const computeColumnWidths = (data: TableData): ColumnWidths => {
  const widthses = data.map((row) => row.map((cell) => cell.length));
  return widthses[0]?.map((_, colIdx) =>
    Math.max(...widthses.map((row) => row[colIdx]))
  ) ?? [];
};

export const computeLayout = (
  data: TableData,
  options: TableOptions
): { data: TableData; colWidths: ColumnWidths } => {
  const transformed = data; // transformers already ran before layout
  validateShape(transformed);
  const colWidths = computeColumnWidths(transformed);
  return Object.freeze({ data: transformed, colWidths });
};