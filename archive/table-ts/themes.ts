/**
 * Built-in themes and default options.
 * All themes are frozen to prevent accidental mutation.
 */
import type { ThemeDefinition, ThemeValue, TableOptions, PartialTableOptions } from "./types";

const MYSQL_THEME: ThemeValue = Object.freeze({
  upperLeft: "+",
  upperRight: "+",
  lowerLeft: "+",
  lowerRight: "+",
  intersection: "+",
  line: "-",
  wall: "|",
  intersectionTop: "+",
  intersectionBottom: "+",
  intersectionLeft: "+",
  intersectionRight: "+",
});

const UNICODE_THEME: ThemeValue = Object.freeze({
  upperLeft: "╔",
  upperRight: "╗",
  lowerLeft: "╚",
  lowerRight: "╝",
  intersection: "╬",
  line: "═",
  wall: "║",
  intersectionTop: "╦",
  intersectionBottom: "╩",
  intersectionLeft: "╠",
  intersectionRight: "╣",
});

const ORACLE_THEME: ThemeValue = Object.freeze({
  upperLeft: "-",
  upperRight: "-",
  lowerLeft: "-",
  lowerRight: "-",
  intersection: "-",
  line: "-",
  wall: "|",
  intersectionTop: "-",
  intersectionBottom: "-",
  intersectionLeft: "-",
  intersectionRight: "-",
});

export const THEMES: ReadonlyArray<ThemeDefinition> = Object.freeze([
  Object.freeze({ title: "MySQL", value: MYSQL_THEME }),
  Object.freeze({ title: "Unicode", value: UNICODE_THEME }),
  Object.freeze({ title: "Oracle", value: ORACLE_THEME }),
]);

const DEFAULT_OPTIONS: TableOptions = Object.freeze({
  title: "",
  padding: 1,
  header: true,
  spreadsheet: false,
  align: false,
  theme: MYSQL_THEME,
});

export { MYSQL_THEME, UNICODE_THEME, ORACLE_THEME };

export const getThemes = (): ReadonlyArray<ThemeDefinition> => THEMES;

export const getThemeByName = (
  name: string
): ThemeValue | undefined => {
  const found = THEMES.find((t) => t.title === name);
  return found?.value;
};

const mergePartialTheme = (
  base: ThemeValue,
  partial?: Partial<ThemeValue>
): ThemeValue => {
  if (partial === undefined) return base;
  return Object.freeze({ ...base, ...partial });
};

export const mergeOptions = (
  partial?: PartialTableOptions
): TableOptions => {
  if (partial === undefined) return DEFAULT_OPTIONS;
  return Object.freeze({
    ...DEFAULT_OPTIONS,
    ...partial,
    theme: mergePartialTheme(DEFAULT_OPTIONS.theme, partial.theme),
  });
};

export { DEFAULT_OPTIONS };