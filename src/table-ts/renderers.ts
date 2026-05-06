/**
 * Renderers — pure string-building functions.
 *
 * Each renderer receives all context it needs (theme, widths, options)
 * and returns a new string. No mutation, no external state.
 */
import type {
  ThemeValue,
  TableOptions,
  TableData,
  ColumnWidths,
  SeparatorType,
} from "./types";
import { titleError } from "./errors";

const buildSeparatorChars = (
  colWidths: ColumnWidths,
  padding: number,
  type: SeparatorType,
  theme: ThemeValue
): string => {
  let result = "";

  switch (type) {
    case "top":
      result += theme.upperLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2 + 1);
        if (i < colWidths.length - 1) result += theme.intersectionTop;
        else result += theme.upperRight;
      }
      break;
    case "bottom":
      result += theme.lowerLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2 + 1);
        if (i < colWidths.length - 1) result += theme.intersectionBottom;
        else result += theme.lowerRight;
      }
      break;
    case "title_top":
      result += theme.upperLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2 + 1);
        if (i < colWidths.length - 1) result += theme.line;
        else result += theme.upperRight;
      }
      break;
    case "title_bottom":
      result += theme.intersectionLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2 + 1);
        if (i < colWidths.length - 1) result += theme.intersectionRight;
        else result += theme.intersectionRight;
      }
      break;
    case "middle":
      result += theme.intersectionLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2 + 1);
        if (i < colWidths.length - 1) result += theme.intersection;
        else result += theme.intersectionRight;
      }
      break;
  }

  return result;
};

const isNumericCell = (value: string): boolean => {
  const trimmed = value.trim().toLowerCase();
  if (trimmed === "null") return true;
  if (!isNaN(parseFloat(trimmed)) && isFinite(Number(trimmed))) return true;
  const dateParsed = Date.parse(trimmed);
  if (!isNaN(dateParsed)) return true;
  return false;
};

const renderCell = (
  value: string,
  colWidth: number,
  padding: number,
  align: boolean
): string => {
  const pad = " ".repeat(padding);
  const targetLen = colWidth + padding * 2;

  if (align && isNumericCell(value)) {
    const leftSpaces = Math.max(0, targetLen - value.length);
    return " ".repeat(leftSpaces) + value + pad;
  }
  const rightSpaces = Math.max(0, targetLen - value.length - pad.length);
  return pad + value + " ".repeat(rightSpaces);
};

const renderRow = (
  row: ReadonlyArray<string>,
  colWidths: ColumnWidths,
  theme: ThemeValue,
  padding: number,
  align: boolean
): string => {
  const cells = row.map((cell, i) =>
    renderCell(cell, colWidths[i], padding, align)
  );
  return theme.wall + cells.join(theme.wall) + theme.wall;
};

const renderTitleBlock = (
  title: string,
  colWidths: ColumnWidths,
  options: TableOptions
): string => {
  const { theme, padding } = options;
  const separator = buildSeparatorChars(colWidths, padding, "title_top", theme);
  const totalLen = separator.length - 2;
  if (title.length > totalLen - 2) {
    titleError("Title is too large");
  }

  const rem = totalLen - 2 - title.length;
  const half = Math.floor(rem / 2);
  const leftPad = " ".repeat(half);
  const rightPad = " ".repeat(half + (rem % 2));

  const titleLine =
    theme.wall +
    leftPad +
    title +
    rightPad +
    theme.wall +
    "\n";

  const bottomLine =
    buildSeparatorChars(colWidths, padding, "title_bottom", theme) + "\n";

  return separator + "\n" + titleLine + bottomLine;
};

const computeTotalWidth = (colWidths: ColumnWidths, padding: number): number => {
  return (
    1 +
    colWidths.reduce((sum, w) => sum + w + padding * 2, 0) +
    colWidths.length +
    1
  );
};

export {
  buildSeparatorChars,
  renderCell,
  renderRow,
  renderTitleBlock,
  computeTotalWidth,
  isNumericCell,
};