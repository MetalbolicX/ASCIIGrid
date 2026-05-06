/**
 * Core type definitions for ASCIIGrid
 * All types are strictly typed to enforce immutability through the pipeline.
 */

export type CellValue = string | number | boolean | null | undefined;

export type ThemeValue = {
  readonly upperLeft: string;
  readonly upperRight: string;
  readonly lowerLeft: string;
  readonly lowerRight: string;
  readonly intersection: string;
  readonly line: string;
  readonly wall: string;
  readonly intersectionTop: string;
  readonly intersectionBottom: string;
  readonly intersectionLeft: string;
  readonly intersectionRight: string;
};

export type BuiltInThemeName = "MySQL" | "Unicode" | "Oracle";

export type TableOptions = {
  readonly title: string;
  readonly padding: number;
  readonly header: boolean;
  readonly spreadsheet: boolean;
  readonly align: boolean;
  readonly theme: ThemeValue;
};

export type PartialTableOptions = Partial<Omit<TableOptions, "theme">> &
  Partial<{ theme: Partial<ThemeValue> }>;

export type ThemeDefinition = {
  readonly title: string;
  readonly value: ThemeValue;
};

export type RowObject = Readonly<Record<string, CellValue>>;

export type InputData =
  | ReadonlyArray<ReadonlyArray<CellValue>>
  | ReadonlyArray<RowObject>;

export type TableData = ReadonlyArray<ReadonlyArray<string>>;

export type ColumnWidths = ReadonlyArray<number>;

export type SeparatorType =
  | "top"
  | "bottom"
  | "title_top"
  | "title_bottom"
  | "middle";

export type PipelineContext = {
  readonly data: TableData;
  readonly options: TableOptions;
  readonly colWidths: ColumnWidths;
};