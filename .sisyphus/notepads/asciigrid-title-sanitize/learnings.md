## Learnings
- `Sanitize.stripAnsiEscapes` can be used directly in `AsciiGridRenderers.res` without a new import because `src/` is a shared ReScript sources tree.
- Sanitizing before both `String.length` and concatenation keeps title centering based on visible characters only.
