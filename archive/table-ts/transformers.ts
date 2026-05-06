/**
 * Data Transformers — spreadsheet mode and header row management.
 *
 * These are pure transformations on TableData. They receive TableData + options
 * and return new TableData. No side effects, no mutations of the input.
 */
import type { TableData, TableOptions } from "./types";

const colLabels = (count: number): ReadonlyArray<string> => {
  const labels: string[] = [];
  for (let i = 0; i < count; i++) {
    labels.push(String.fromCharCode(65 + i));
  }
  return labels;
};

const prependRowIndex = (
  rows: TableData,
  headerEnabled: boolean
): TableData => {
  return rows.map((row, idx) => {
    let indexStr: string;
    if (headerEnabled) {
      indexStr = idx === 0 ? " " : String(idx - 1);
    } else {
      indexStr = idx === 0 ? "1" : String(idx + 1);
    }
    return [indexStr, ...row];
  });
};

export const applySpreadsheetMode = (
  data: TableData,
  options: TableOptions
): TableData => {
  if (!options.spreadsheet) return data;

  const numCols = data[0]?.length ?? 0;
  if (numCols === 0) return data;

  const spreadsheetRow: readonly string[] = colLabels(numCols);
  const withHeader = [spreadsheetRow, ...data];
  return prependRowIndex(withHeader, options.header);
};

export const applyHeaderFlag = (
  data: TableData,
  options: TableOptions
): TableData => {
  if (options.spreadsheet) return data;
  return data;
};