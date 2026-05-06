/**
 * Pipeline — composes all stages into a single renderTable call.
 *
 * PIPELINE COMPOSITION
 * --------------------
 * renderTable is a left-to-right composition of pure stages:
 *
 *   adaptInputData  → transformers → layout → render
 *   (InputData)       (TableData)    (layout)  (string)
 *
 * Each stage is a pure function. Options are threaded through implicitly
 * via closure so no stage ever reads from or mutates shared state.
 *
 * The result is a single pure function: same input always yields same output.
 */
import type { InputData, TableOptions, TableData, ColumnWidths } from "./types";
import { adaptInputData } from "./adapters";
import { applySpreadsheetMode } from "./transformers";
import { validateShape, computeColumnWidths } from "./layout";
import {
  buildSeparatorChars,
  renderRow,
  renderTitleBlock,
  computeTotalWidth,
} from "./renderers";
import { mergeOptions } from "./themes";

const renderTableData = (
  data: TableData,
  colWidths: ColumnWidths,
  options: TableOptions
): string => {
  validateShape(data);
  const { theme, padding, title, header, spreadsheet, align } = options;

  const lines: string[] = [];

  if (title !== "") {
    lines.push(renderTitleBlock(title, colWidths, options));
  } else {
    lines.push(buildSeparatorChars(colWidths, padding, "top", theme) + "\n");
  }

  for (let i = 0; i < data.length; i++) {
    const row = data[i];
    lines.push(renderRow(row, colWidths, theme, padding, align) + "\n");

    if (spreadsheet) {
      if (i === 0) {
        lines.push(buildSeparatorChars(colWidths, padding, "middle", theme) + "\n");
      }
      if (header && i === 1) {
        lines.push(buildSeparatorChars(colWidths, padding, "middle", theme) + "\n");
      }
    } else {
      if (header && i === 0) {
        lines.push(buildSeparatorChars(colWidths, padding, "middle", theme) + "\n");
      }
    }
  }

  lines.push(buildSeparatorChars(colWidths, padding, "bottom", theme));

  return lines.join("");
};

const calculateColumnWidths = (data: TableData): ColumnWidths => {
  return data[0]?.map((_, colIdx) =>
    Math.max(...data.map((row) => (row[colIdx] ?? "").length))
  ) ?? [];
};

const applyTransformations = (
  data: TableData,
  options: TableOptions
): TableData => {
  return applySpreadsheetMode(data, options);
};

export const renderTable = (
  input: InputData,
  partialOptions?: Partial<TableOptions>
): string => {
  const options = mergeOptions(partialOptions);

  const normalized: TableData = adaptInputData(input);
  const transformed: TableData = applyTransformations(normalized, options);
  const colWidths: ColumnWidths = calculateColumnWidths(transformed);

  return renderTableData(transformed, colWidths, options);
};