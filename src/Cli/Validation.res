/**
 * CLI validation helpers for ASCIIGrid.
 *
 * Fail-fast validation for user-facing CLI arguments before they reach the
 * rest of the command pipeline.
 *
 * @module Validation
 */

let validateTitle = (raw: string): result<string, string> => {
  let title = String.trim(raw)
  if String.length(title) == 0 {
    Error("Title cannot be empty")
  } else {
    Ok(title)
  }
}

let validateTimeout = (timeout: int): result<int, string> => {
  if timeout == 0 || (timeout >= 1 && timeout <= 300) {
    Ok(timeout)
  } else {
    Error("Timeout must be 0 (disabled) or between 1 and 300 seconds")
  }
}

let validateMaxRows = (maxRows: int): result<int, string> => {
  if maxRows > 0 {
    Ok(maxRows)
  } else {
    Error("Max rows must be greater than 0")
  }
}
