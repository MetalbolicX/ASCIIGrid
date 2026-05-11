/**
 * Sanitizes terminal output by stripping ANSI escapes and control chars.
 *
 * @module Sanitize
 */

@new external makeRe: (string, string) => RegExp.t = "RegExp"

let stripAnsiEscapes = (input: string): string => {
  let r1 = makeRe("\\x1b\\[[0-9;]*[A-Za-z]", "g")
  let r2 = makeRe("\\x1b.", "g")
  let r3 = makeRe("[\\x01-\\x08\\x0B\\x0C\\x0E-\\x1F]", "g")
  input->String.replaceRegExp(r1, "")->String.replaceRegExp(r2, "")->String.replaceRegExp(r3, "")
}
