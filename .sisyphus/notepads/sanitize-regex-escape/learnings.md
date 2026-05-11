## Learnings
- ReScript `%re(...)` emitted escaped backslashes that produced literal `\x1b` in JS regex literals.
- Binding `new RegExp(pattern, flags)` with `@new external` keeps ESC escapes correct at runtime.
- `RegExp.t` avoids the deprecation warning that `Js.Re.t` now triggers.
