open Test

let assertStringEqual = (expected: string, actual: string, message: string) =>
  assertion((a, b) => a == b, expected, actual, ~operator="String equals to", ~message)

test("strips ansi codes from text", () => {
  let actual = Sanitize.stripAnsiEscapes("Hello\x1b[32mWorld\x1b[0m")
  assertStringEqual("HelloWorld", actual, "ansi escapes should be removed")
})

test("keeps normal text unchanged", () => {
  let actual = Sanitize.stripAnsiEscapes("Normal text")
  assertStringEqual("Normal text", actual, "plain text should stay the same")
})

test("returns empty string for empty input", () => {
  let actual = Sanitize.stripAnsiEscapes("")
  assertStringEqual("", actual, "empty input should stay empty")
})

test("removes escape-only input", () => {
  let actual = Sanitize.stripAnsiEscapes("\x1b[5m\x1b[31m")
  assertStringEqual("", actual, "escape-only input should become empty")
})

test("strips non-printable characters but keeps whitespace controls", () => {
  let actual = Sanitize.stripAnsiEscapes("\x01Hello\tWorld\n\r\x1f")
  assertStringEqual("Hello\tWorld\n\r", actual, "control chars below 0x20 should be removed")
})
