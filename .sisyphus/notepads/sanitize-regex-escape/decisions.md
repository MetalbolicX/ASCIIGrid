## Decisions
- Switched ANSI/control-char regex construction from `%re(...)` literals to runtime `RegExp` construction.
- Kept behavior identical and limited the fix to `src/utils/Sanitize.res` plus regenerated output.
