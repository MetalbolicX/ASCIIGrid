# Issues / Gotchas

## ReScript Regex
- ReScript uses `Js.Re` / `RegExp` for regex - NOT native JS `/.../g` syntax
- Pattern: `let re = %re("/\\x1b\\[[0-9;]*[a-zA-Z]/g")`
- Apply with: `Js.Re.exec_` or string replace bindings

## rescript.json sources
- `src/utils/` directory must be added to rescript.json sources if not covered by `subdirs: true`
- Check: `{ "dir": "src", "subdirs": true }` covers all subdirs including new `utils/` — OK

## Coverage with retest
- retest is a simple test runner for .res.mjs files
- c8 wraps any command: `c8 --all --include='src/**' retest ./test/res/**/*.res.mjs`
