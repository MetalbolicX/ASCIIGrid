/**
 * Custom error types for ASCIIGrid.
 * All errors extend Error with a `type` property for caller inspection.
 */
export class TableError extends Error {
  constructor(
    message: string,
    public readonly type: "input" | "title"
  ) {
    super(message);
    this.name = "TableError";
    Object.setPrototypeOf(this, TableError.prototype);
  }
}

export const inputError = (message: string): never => {
  throw new TableError(message, "input");
};

export const titleError = (message: string): never => {
  throw new TableError(message, "title");
};