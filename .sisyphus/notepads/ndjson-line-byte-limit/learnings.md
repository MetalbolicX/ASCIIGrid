# Learnings

## Project Stack
- ReScript 12.2 compiled to ESM JavaScript
- Node.js >=22 required
- CLI bundled via rolldown → dist/cli.mjs
- Tests: Plain Node.js spawnSync + assert (no framework) in test/cli/Cli_test.mjs

## Key Patterns
- `parseMaxRows` (CliEntry.res:21-35) is the canonical pattern for numeric flag parsing: None → default, invalid → default, negative → default
- Exit code 1 = limit violation (--max-rows precedent)
- Exit code 2 = parse error
- `cliOptions` type lives in `src/bindings/Bindings.res` at line 107-124
- `parseArgs` dict in `run` at CliEntry.res:402-424
- Signal handlers registered at start of `run` (lines 682-689)
- `parseNdjsonStreaming` signature at line 117; `processLine` at line 243

## Guardrails
- Byte check MUST be BEFORE jsonParse (not inside try/catch around it)
- New flag must be configurable (not hardcoded)
- Default = 10_000_000 (10MB)
- Don't modify parseMaxRows — add separate parseMaxLineBytes

## Verification
- `npm run res:build` completed successfully after wiring `~maxLineBytes` through `parseNdjsonStreaming` and `streamNdjsonFromFile`
- `lsp_diagnostics` is not available for `.res` in this workspace, so file-level LSP verification could not run here
