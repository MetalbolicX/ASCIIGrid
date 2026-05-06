/**
 * Input Adapter — detects input shape and normalizes to TableData.
 *
 * ADAPTER PATTERN (Pipeline Stage 1)
 * ----------------------------------
 * The adapter is the first stage in the data pipeline. It accepts `InputData`
 * (either a 2D matrix or an array of row-objects) and returns a canonical
 * `TableData` (ReadonlyArray<ReadonlyArray<string>>).
 *
 * For object rows:
 *   - All unique keys are collected in encounter order across all rows.
 *   - The header row is built from those keys (stringified).
 *   - Each row is mapped to a column array using the same key order.
 *   - Missing keys yield empty strings.
 *
 * This normalizes the shape before any other transformation runs, allowing
 * all downstream stages to work on a consistent 2D string matrix regardless
 * of the caller's input format.
 */
import type { InputData, TableData, RowObject, CellValue } from "./types";

const isObjectRow = (value: unknown): value is RowObject =>
  value !== null &&
  typeof value === "object" &&
  !Array.isArray(value);

const isObjectRowArray = (input: InputData): input is ReadonlyArray<RowObject> =>
  input.length > 0 && isObjectRow(input[0]);

const stringifyCell = (value: CellValue): string => {
  if (value === null || value === undefined) return "";
  return String(value);
};

const extractKeysInOrder = (rows: ReadonlyArray<RowObject>): ReadonlyArray<string> => {
  const seen = new Set<string>();
  const keys: string[] = [];
  for (const row of rows) {
    for (const key of Object.keys(row)) {
      if (!seen.has(key)) {
        seen.add(key);
        keys.push(key);
      }
    }
  }
  return keys;
};

const adaptObjectRows = (rows: ReadonlyArray<RowObject>): TableData => {
  const keys = extractKeysInOrder(rows);
  const header: readonly string[] = keys.map(stringifyCell);
  const body: readonly (readonly string[])[] = rows.map((row) =>
    keys.map((k) => stringifyCell(row[k]))
  );
  return [header, ...body];
};

const adaptMatrix = (matrix: ReadonlyArray<ReadonlyArray<CellValue>>): TableData =>
  matrix.map((row) => row.map(stringifyCell));

export const adaptInputData = (input: InputData): TableData => {
  if (isObjectRowArray(input)) {
    return adaptObjectRows(input);
  }
  return adaptMatrix(input as ReadonlyArray<ReadonlyArray<CellValue>>);
};

export { isObjectRowArray };