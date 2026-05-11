# Fix NDJSON Line Byte Limit — Prevent OOM on Oversized Lines

## TL;DR

> **Quick Summary**: Add a per-line byte limit to the NDJSON streaming parser to prevent OOM crashes when a single line exceeds available memory.
>
> **Deliverables**:
> - `--max-line-bytes` CLI flag with 10MB default cap
> - Guard in `processLine` before `jsonParse` — fail fast, not after allocation
> - Integration test for oversized line rejection
>
> **Estimated Effort**: Short
> **Parallel Execution**: NO — sequential (small task)
> **Critical Path**: Task 1 → Task 2 → Task 3 → Task 4 → Task 5

---

## Context

### Original Request
Production readiness review identified a catastrophic edge case: `parseNdjsonStreaming` has no per-line byte limit. A single NDJSON line with a 100MB+ string value exhausts process memory and crashes with no recovery.

### The Bug
In `src/Cli/CliEntry.res`, the `processLine` function (line 243) calls `jsonParse(trimmed)` without checking line byte length. The `--max-rows` flag only counts rows, not bytes. A malicious or malformed NDJSON file with one enormous line will OOM before any guard triggers.

### Root Cause
Line size is never validated before attempting to parse. The fix needs to:
1. Add a configurable byte limit (default 10MB)
2. Check BEFORE calling `jsonParse` — not after memory is already consumed
3. Return exit code `1` (limit violation) matching `--max-rows` precedent

---

## Work Objectives

### Core Objective
Prevent OOM crashes from oversized NDJSON lines by adding a configurable `--max-line-bytes` guard that fails fast before attempting to parse a line.

### Concrete Deliverables
- New CLI flag `--max-line-bytes <n>` (default: `10000000` = 10MB)
- Byte check in `processLine` BEFORE `jsonParse` is called
- Exit code `1` on limit violation (consistent with `--max-rows`)
- Integration test covering oversized line rejection

### Definition of Done
- [ ] `echo '{"data":"X"...10MB...' | asciigrid --format ndjson` returns exit code `1` before OOM
- [ ] Default 10MB cap works without explicit flag
- [ ] `--max-line-bytes 1000` rejects a 1KB line
- [ ] Existing NDJSON tests still pass

### Must Have
- Per-line byte check BEFORE `jsonParse` in `parseNdjsonStreaming`
- `--max-line-bytes` flag wired into `run` and passed into `parseNdjsonStreaming`
- Exit code `1` on violation (matches `--max-rows` pattern)

### Must NOT Have (Guardrails)
- No check AFTER `jsonParse` — that defeats the purpose
- No hardcoded limit without a flag — must be configurable
- No `JSON.parse` call inside try/catch for the size check — must be before the parse attempt

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: NO (tests-after for this fix)
- **Framework**: Plain Node.js `spawnSync` + `assert` (existing pattern)
- **Agent-Executed QA**: Every task verified by running the CLI directly

---

## TODOs

- [x] 1. Add `parseMaxLineBytes` helper in CliEntry.res

  **What to do**:
  - Add `parseMaxLineBytes` function mirroring `parseMaxRows` pattern (lines 21-35)
  - Default: `10000000` (10MB)
  - Invalid/negative values fall back to default
  - Returns `int` not wrapped in result (like `parseMaxRows`)

  **Must NOT do**:
  - Don't use a result type — match `parseMaxRows` style

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - **Reason**: Trivial helper function, one-off addition

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: Task 2

  **References**:
  - `src/Cli/CliEntry.res:21-35` — `parseMaxRows` pattern to mirror exactly

  **Acceptance Criteria**:
  - [ ] `parseMaxLineBytes(None)` returns `10000000`
  - [ ] `parseMaxLineBytes(Some("5000000"))` returns `5000000`
  - [ ] `parseMaxLineBytes(Some("-5"))` returns `10000000` (invalid → default)

---

- [x] 2. Wire `--max-line-bytes` into `parseArgs` and `run`

  **What to do**:
  - Add `"max-line-bytes"` to `options` dict in `parseArgs` (line ~404-423) — type `"string"`, default `Bindings.Util.String("10000000")`
  - Add `maxLineBytes` to the options object built in `run` (line ~720-727)
  - Pass `maxLineBytes` as parameter to `parseNdjsonStreaming` calls (lines 742-756)
  - Add `--max-line-bytes` to `helpText` and README CLI reference table

  **Must NOT do**:
  - Don't change the exit code for existing errors
  - Don't modify `parseMaxRows` — keep it separate

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - **Reason**: CLI argument wiring, single-file change

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: Task 3
  - **Blocked By**: Task 1

  **References**:
  - `src/Cli/CliEntry.res:402-424` — `parseArgs` function to modify
  - `src/Cli/CliEntry.res:720-727` — options object in `run`
  - `src/Cli/CliEntry.res:380-398` — `helpText` to update
  - `README.md:40-57` — CLI reference table

  **Acceptance Criteria**:
  - [ ] `--help` shows `--max-line-bytes` with default `10000000`
  - [ ] `asciigrid --format ndjson --max-line-bytes 5000000 --help` shows custom value

---

- [x] 3. Add byte limit check in `processLine` BEFORE `jsonParse`

  **What to do**:
  - Add `maxLineBytes: int` parameter to `parseNdjsonStreaming` signature (line ~117)
  - In `processLine` (line 243), BEFORE calling `jsonParse(trimmed)`, add:
    ```rescript
    if trimmed->String.length > maxLineBytes {
      finish(Error((1, "Line exceeds maximum byte limit: " ++ Int.toString(maxLineBytes))))
    }
    ```
  - The check must be BEFORE the try/catch that wraps `jsonParse` — not inside it
  - Update both call sites of `parseNdjsonStreaming` to pass the new parameter

  **Must NOT do**:
  - Don't check AFTER `jsonParse` — that defeats the OOM prevention
  - Don't put the check inside the try/catch

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - **Reason**: Small targeted change inside existing function

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: Task 4, Task 5
  - **Blocked By**: Task 2

  **References**:
  - `src/Cli/CliEntry.res:117` — `parseNdjsonStreaming` function signature
  - `src/Cli/CliEntry.res:243-276` — `processLine` function where guard goes

  **Acceptance Criteria**:
  - [ ] 15MB line rejected with exit code `1` before OOM
  - [ ] 5MB line accepted with default 10MB cap
  - [ ] Error message mentions byte limit

  **QA Scenarios**:
  ```
  Scenario: Oversized line rejected before parse (OOM prevention)
    Tool: Bash
    Preconditions: Built CLI at dist/cli.mjs
    Steps:
      1. Generate 15MB JSON line: `printf '{"data":"%sv"}' "$(printf 'x%.0s' {1..15000000})" > /tmp/oversized.ndjson`
      2. Run: `node dist/cli.mjs --format ndjson --input /tmp/oversized.ndjson`
    Expected Result: Exit code 1, no OOM crash, error message about byte limit
    Evidence: .sisyphus/evidence/task3-oom-prevention.txt
  ```

---

- [x] 4. Add integration test for oversized line rejection

  **What to do**:
  - In `test/cli/Cli_test.mjs`, add a test block after the existing NDJSON tests (around line 73)
  - Test using `spawnSync` with a constructed oversized line via stdin
  - Verify: exit code 1, no OOM crash, stderr contains byte limit message
  - Also test explicit `--max-line-bytes` flag override

  **Must NOT do**:
  - Don't test 100MB+ in unit test — just test rejection boundary (e.g., 100 byte limit on 200 byte line)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - **Reason**: Simple integration test addition using existing patterns

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: None (independent test)
  - **Blocked By**: Task 3

  **References**:
  - `test/cli/Cli_test.mjs:38-73` — existing test patterns to follow
  - `test/cli/Cli_test.mjs:46-63` — JSON stdin test pattern

  **Acceptance Criteria**:
  - [ ] `runCliWithStdin('--format ndjson --max-line-bytes 10', '{"data":"12345678901"}')` returns status 1
  - [ ] No OOM crash on the test

---

- [x] 5. Update README.md CLI reference table

  **What to do**:
  - Add `--max-line-bytes` row to the CLI reference table in README.md (around line 54)
  - Default value: `10000000`
  - Description: `Maximum bytes per NDJSON line (default: 10000000)`

  **Must NOT do**:
  - Don't rewrite the entire README — only add the row

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: []
  - **Reason**: Simple documentation update

  **Parallelization**:
  - **Can Run In Parallel**: YES (independent of implementation)
  - **Blocks**: None

  **References**:
  - `README.md:40-57` — CLI reference table structure

  **Acceptance Criteria**:
  - [ ] New row appears in correct position in table
  - [ ] Default value shown as `10000000`

---

## Final Verification Wave

- [x] F1. **OOM Prevention Test** — `quick`
  Run a test that sends a 15MB line through NDJSON streaming. Verify exit code 1 and no OOM crash. Evidence saved to `.sisyphus/evidence/f1-oom-prevention.txt`

- [x] F2. **Default Cap Test** — `quick`
  Run without `--max-line-bytes`. Verify 10MB line passes, 20MB line is rejected. Evidence to `.sisyphus/evidence/f2-default-cap.txt`

- [x] F3. **Explicit Flag Test** — `quick`
  Run with `--max-line-bytes 1000`. Verify 1KB line rejected. Evidence to `.sisyphus/evidence/f3-explicit-flag.txt`

---

## Commit Strategy

- **1**: `fix(cli): add --max-line-bytes to prevent OOM on oversized NDJSON lines`

---

## Success Criteria

```bash
# Oversized line rejected with exit code 1 (no OOM)
printf '{"data":"%sv"}' "$(printf 'x%.0s' {1..15000000})" | node dist/cli.mjs --format ndjson; echo "Exit: $?"

# With explicit flag
printf '{"data":"1234"}' | node dist/cli.mjs --format ndjson --max-line-bytes 3; echo "Exit: $?"
```