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

  // Each segment is: padding + content + padding = colWidth + padding*2 chars.
  // No extra +1 — the connector character itself is added separately.
  switch (type) {
    case "top":
      result += theme.upperLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2);
        result += i < colWidths.length - 1 ? theme.intersectionTop : theme.upperRight;
      }
      break;
    case "bottom":
      result += theme.lowerLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2);
        result += i < colWidths.length - 1 ? theme.intersectionBottom : theme.lowerRight;
      }
      break;
    case "title_top":
      // Title spans all columns — no intermediate connectors, just a plain top border.
      result += theme.upperLeft;
      result += theme.line.repeat(
        colWidths.reduce((s, w) => s + w + padding * 2, 0) + (colWidths.length - 1)
      );
      result += theme.upperRight;
      break;
    case "title_bottom":
      // Transition from title row to table body — uses full-width connectors.
      result += theme.intersectionLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2);
        result += i < colWidths.length - 1 ? theme.intersection : theme.intersectionRight;
      }
      break;
    case "middle":
      result += theme.intersectionLeft;
      for (let i = 0; i < colWidths.length; i++) {
        result += theme.line.repeat(colWidths[i] + padding * 2);
        result += i < colWidths.length - 1 ? theme.intersection : theme.intersectionRight;
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
    // Right-align: reserve right pad, left-fill remainder.
    const leftSpaces = Math.max(0, targetLen - value.length - pad.length);
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
  // totalLen = inner width between the two corner characters.
  const totalLen = separator.length - 2;
  if (title.length > totalLen - 2) {
    titleError("Title is too large");
  }

  // title + left + right pads must fill exactly totalLen chars.
  const rem = totalLen - title.length;
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