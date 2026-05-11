# ASCIIGrid Production Readiness Improvements

## TL;DR

> **Quick Summary**: Hardening ASCIIGrid for production by adding ANSI escape sanitization, CI vulnerability scanning, coverage thresholds, and fail-fast CLI validation.
>
> **Deliverables**:
> - ANSI-safe string sanitization utility for user-provided text
> - Updated `AsciiGridRenderers` to sanitize title input
> - CI job for `npm audit` dependency vulnerability scanning
> - Coverage threshold enforcement in CI
> - Fail-fast validation for required CLI arguments
>
> **Estimated Effort**: Short
> **Parallel Execution**: YES - waves 1 and 2 can overlap
> **Critical Path**: Task 1 → Task 4 → Task 7

---

## Context

### Original Request
User requested a production readiness review of ASCIIGrid (a ReScript CLI for rendering ASCII tables). Review identified 4 gaps across security, CI, and configuration.

### Interview Summary
**Key Discussions**:
- Security gap: No ANSI escape sanitization on user text inputs (terminal injection risk)
- CI gap: No dependency CVE scanning
- CI gap: No coverage threshold enforcement
- Configuration gap: No fail-fast validation on required CLI args

### Metis Review
**Identified Gaps** (addressed):
- Scope creep risk: Must NOT modify AsciiGrid core rendering logic
- Edge case: title with only escape sequences (should become empty or sanitized)
- CI ambiguity: Coverage tool needs to be compatible with `retest` (ReScript test runner)

---

## Work Objectives

### Core Objective
Improve production readiness of ASCIIGrid CLI tool with 4 targeted improvements.

### Concrete Deliverables
- `src/utils/Sanitize.res` - ANSI escape sequence stripping utility
- `src/Cli/CliEntry.res` - Updated to use sanitization on title and input
- `.github/workflows/ci.yml` - Added `npm audit` and coverage threshold step
- Validation functions for CLI argument fail-fast

### Definition of Done
- [ ] `npm run res:build` succeeds with no errors
- [ ] `npm run res:test` passes all tests
- [ ] `npm run bundle` produces valid CLI bundle
- [ ] `npm run test:cli` passes all CLI integration tests

### Must Have
- ANSI escape sequences stripped from title and cell content before rendering
- Dependency vulnerability scan runs in CI on every PR
- Coverage reports generated and threshold enforced

### Must NOT Have (Guardrails)
- No changes to AsciiGrid core box-drawing rendering logic
- No new external runtime dependencies (use built-in tools only)
- No breaking changes to the public API

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: Tests-after (existing tests must pass)
- **Framework**: retest (ReScript test runner)
- **Additional**: CLI integration tests via `node test/cli/Cli_test.mjs`

### QA Policy
Every task includes agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

---

## Execution Strategy

### Parallel Execution Waves

  ```

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists. For each "Must NOT Have": search codebase for forbidden patterns. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `npm run res:build` + `npm run res:test`. Review all changed files for: `as any`/`@ts-ignore`, empty catches, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction.
  Output: `Build [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration (features working together). Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance. Detect cross-task contamination.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

- **1-3**: `chore(security): add production readiness improvements` - Tasks 1, 2, 3
- **4-6**: `feat(production): complete hardening` - Tasks 4, 5, 6
- **Pre-commit**: `npm run res:build && npm run res:test`

---

## Success Criteria

### Verification Commands
```bash
npm run res:build      # Expected: no errors
npm run res:test      # Expected: all tests pass
npm run bundle        # Expected: dist/cli.mjs created
npm run test:cli      # Expected: all CLI tests pass
npm audit             # Expected: 0 vulnerabilities
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All tests pass
- [ ] CI includes audit step
- [ ] CI includes coverage threshold
- [ ] ANSI sanitization integrated
Wave 2 (After Wave 1 - integration + coverage):
├── Task 4: Integrate sanitization into AsciiGridRenderers (title)
├── Task 5: Integrate sanitization into CliEntry (cell content)
└── Task 6: Configure and add coverage threshold to CI

Wave FINAL (After ALL tasks — 4 parallel reviews):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review
├── Task F3: Real manual QA
└── Task F4: Scope fidelity check
-> Present results -> Get explicit user okay
```

### Dependency Matrix
- **1**: - - 4, 5
- **4**: 1 - 7, F1-F4
- **5**: 1 - 7, F1-F4
- **7**: 4, 5, 6 - F1-F4

### Agent Dispatch Summary
- **Wave 1**: 3 tasks → `quick` (utility + validation + CI update)
- **Wave 2**: 3 tasks → `quick` (sanitization integration + coverage CI)
- **FINAL**: 4 reviews → `oracle`, `unspecified-high`, `unspecified-high`, `deep`

---

## TODOs

- [x] 1. Create ANSI Sanitization Utility

  **What to do**:
  - Create `src/utils/Sanitize.res` module
  - Implement `stripAnsiEscapes: string => string` function
  - Strip ESC sequences: `\x1b[...` patterns (ANSI CSI SGR sequences)
  - Also strip non-printable characters except tab/newline/carriage return
  - Add test cases: normal text, ANSI codes, mixed content, empty string

  **Must NOT do**:
  - Do NOT add external dependencies (pure ReScript only)
  - Do NOT modify core AsciiGrid rendering

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple utility function, minimal logic
  - **Skills**: []
    - No specialized skills needed

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: Tasks 4, 5
  - **Blocked By**: None

  **References**:
  - `src/grid/AsciiGridTheme.res:1-76` - Module structure pattern to follow
  - `src/Logger.res:7-48` - Structured logging approach for debugging
  - `Bindings.res:1-120` - External bindings pattern for Node.js interop

  **Acceptance Criteria**:
  - [ ] `src/utils/Sanitize.res` created with module type
  - [ ] `stripAnsiEscapes("Hello\x1b[32mWorld\x1b[0m")` returns `"HelloWorld"`
  - [ ] `stripAnsiEscapes("Normal text")` returns `"Normal text"`
  - [ ] `stripAnsiEscapes("")` returns `""`
  - [ ] `stripAnsiEscapes("\x1b[5m\x1b[31m")` returns `""` (escape-only becomes empty)
  - [ ] No new test failures in `npm run res:test`

  **QA Scenarios**:

  ```
  Scenario: CI passes when no vulnerabilities present
    Tool: Bash
    Preconditions: Clean state, all dependencies clean
    Steps:
      1. Run `npm audit` locally
      2. Verify exit code is 0 (no vulnerabilities)
    Expected Result: Exit code 0, no audit output showing vulnerabilities
    Evidence: .sisyphus/evidence/task-3-audit-pass.{ext}
  ```

- [x] 4. Integrate Sanitization into AsciiGridRenderers (title)

  **What to do**:
  - Read `src/grid/AsciiGridRenderers.res`
  - Import Sanitize module
  - Apply `Sanitize.stripAnsiEscapes` to title text in `buildTitleLine` function
  - Verify all existing tests still pass

  **Must NOT do**:
  - Do NOT modify border character rendering
  - Do NOT change the theme system
  - Do NOT add new public functions

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small targeted edit, follows existing patterns

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6)
  - **Blocks**: Task 7 (Final integration)
  - **Blocked By**: Task 1 (Sanitize module must exist)

  **References**:
  - `src/grid/AsciiGridRenderers.res` - Existing buildTitleLine function
  - `src/utils/Sanitize.res` - Sanitize.stripAnsiEscapes function
  - `src/grid/AsciiGridTheme.res` - Theme types for reference

  **Acceptance Criteria**:
  - [ ] AsciiGridRenderers imports Sanitize module
  - [ ] Title text is sanitized before rendering
  - [ ] Existing title tests still pass
  - [ ] ANSI escape codes in title do not appear in output

  **QA Scenarios**:

  ```
  Scenario: Title with ANSI codes renders safely
    Tool: interactive_bash (tmux)
    Preconditions: CLI built with sanitization integrated
    Steps:
      1. echo '[["A","B"],["1","2"]]' | node dist/cli.mjs --title $'\x1b[31mRed Title\x1b[0m'
      2. Check stdout for "Red Title" without ANSI escape sequences
    Expected Result: Table renders with "Red Title" visible, no raw escape codes
    Evidence: .sisyphus/evidence/task-4-title-sanitized.{ext}

  Scenario: Normal title without ANSI codes still works
    Tool: interactive_bash (tmux)
    Preconditions: CLI built
    Steps:
      1. echo '[["A","B"],["1","2"]]' | node dist/cli.mjs --title "Normal Title"
      2. Verify table renders correctly with title
    Expected Result: Exit code 0, table visible with "Normal Title"
    Evidence: .sisyphus/evidence/task-4-normal-title.{ext}
  ```

- [x] 5. Integrate Sanitization into CliEntry (cell content)

  **What to do**:
  - Read `src/Cli/CliEntry.res`
  - Apply sanitization to title in argument parsing
  - Apply sanitization to cell content when `--rich` flag is used
  - Update error messages to indicate sanitization occurred

  **Must NOT do**:
  - Do NOT change the streaming parser logic
  - Do NOT add latency to the hot path (sanitize only at output, not per-line)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Targeted edits, follows existing patterns

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 6)
  - **Blocks**: Task 7
  - **Blocked By**: Task 1 (Sanitize module must exist)

  **References**:
  - `src/Cli/CliEntry.res:54-71` - stringifyJsonCell function
  - `src/Cli/CliEntry.res:117-280` - Streaming parser flow
  - `src/grid/AsciiGridAdapters.res` - Cell value types

  **Acceptance Criteria**:
  - [ ] Title argument is sanitized before being passed to render
  - [ ] Rich cell content is sanitized before being passed to render
  - [ ] String cell content is sanitized before being passed to render
  - [ ] All CLI tests pass with sanitized inputs

  **QA Scenarios**:

  ```
  Scenario: Rich mode with ANSI in cell values
    Tool: interactive_bash (tmux)
    Preconditions: CLI built with sanitization
    Steps:
      1. echo '{"Name": "\x1b[32mGreen\x1b[0m"}' | node dist/cli.mjs --rich --format ndjson
      2. Verify output shows "Green" without ANSI codes
    Expected Result: Cell renders with plain "Green" text
    Evidence: .sisyphus/evidence/task-5-rich-sanitized.{ext}

  Scenario: JSON mode with ANSI in cell values
    Tool: interactive_bash (tmux)
    Preconditions: CLI built
    Steps:
      1. echo '[["Name"],["\x1b[31mRed\x1b[0m"]]' | node dist/cli.mjs
      2. Verify output shows "Red" without ANSI codes
    Expected Result: Cell renders with plain "Red" text
    Evidence: .sisyphus/evidence/task-5-json-sanitized.{ext}
  ```

- [x] 6. Configure Coverage Threshold in CI

  **What to do**:
  - Research: retest coverage output format (likely JSON or text)
  - Add coverage reporting to `npm run res:test` if not already present
  - Add `nyc` or equivalent to enforce 70% coverage threshold
  - Update CI workflow to fail if coverage drops below threshold

  **Must NOT do**:
  - Do NOT lower threshold below 70% without user approval
  - Do NOT add coverage for `test/` directory (dev only)
  - Do NOT add coverage for bindings/external modules

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: CI configuration update, straightforward

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5)
  - **Blocks**: None (CI-only change)
  - **Blocked By**: None

  **References**:
  - `.github/workflows/ci.yml` - Existing CI structure
  - `package.json` - Existing test scripts
  - retest documentation for coverage output format

  **Acceptance Criteria**:
  - [ ] `npm run res:test -- --coverage` (or equivalent) generates coverage report
  - [ ] Coverage threshold set to 70%
  - [ ] CI job fails if coverage drops below threshold
  - [ ] Coverage report generated as artifact in CI

  **QA Scenarios**:

  ```
  Scenario: CI fails when coverage is below threshold
    Tool: Bash (git)
    Preconditions: All tests passing, coverage adequate
    Steps:
      1. Temporarily comment out a test case
      2. Run coverage locally to verify it drops
      3. Verify threshold would fail CI (even if locally passing)
    Expected Result: Coverage would fall below 70%, CI would block
    Evidence: .sisyphus/evidence/task-6-coverage-fail.{ext}

  Scenario: CI passes with adequate coverage
    Tool: Bash
    Preconditions: All tests present, no modifications
    Steps:
      1. Run coverage locally
      2. Verify coverage >= 70%
    Expected Result: Coverage output shows >= 70%, CI would pass
    Evidence: .sisyphus/evidence/task-6-coverage-pass.{ext}
  ```


- [x] 2. Create CLI Argument Validation Module

  **What to do**:
  - Create `src/Cli/Validation.res` module
  - Implement `validateTitle: string => result<string, string>` - fail-fast on empty title after trim
  - Implement `validateTimeout: int => result<int, string>` - validate timeout bounds (0 = disabled, max 300s)
  - Implement `validateMaxRows: int => result<int, string>` - fail-fast on negative
  - Export typed error helpers

  **Must NOT do**:
  - Do NOT add runtime exceptions - use result types
  - Do NOT duplicate existing validation (parseMaxRows handles conversion)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple validation functions, straightforward logic

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: Task 5 (CliEntry integration)
  - **Blocked By**: None

  **References**:
  - `src/Cli/CliEntry.res:21-35` - Existing parseMaxRows pattern
  - `src/grid/AsciiGridOptions.res` - Options types to reference for bounds

  **Acceptance Criteria**:
  - [ ] `src/Cli/Validation.res` created
  - [ ] `validateTitle("")` returns `Error("Title cannot be empty")`
  - [ ] `validateTitle("   ")` returns `Error("Title cannot be empty")` after trim
  - [ ] `validateTitle("Valid Title")` returns `Ok("Valid Title")`
  - [ ] `validateTimeout(-1)` returns `Error("Timeout must be non-negative")`
  - [ ] `validateTimeout(301)` returns `Error("Timeout cannot exceed 300 seconds")`
  - [ ] `validateTimeout(60)` returns `Ok(60)`

  **QA Scenarios**:

  ```
  Scenario: Fail-fast on empty title via CLI
    Tool: interactive_bash (tmux)
    Preconditions: CLI built at dist/cli.mjs
    Steps:
      1. echo '[["A","B"],["1","2"]]' | node dist/cli.mjs --title ""
      2. Verify CLI exits with non-zero code and error message
    Expected Result: Exit code != 0, message contains "empty" or "Title"
    Evidence: .sisyphus/evidence/task-2-validation.{ext}

  Scenario: Valid title passes validation
    Tool: interactive_bash (tmux)
    Preconditions: CLI built
    Steps:
      1. echo '[["A","B"],["1","2"]]' | node dist/cli.mjs --title "Valid Table"
      2. Verify table renders correctly with title
    Expected Result: Exit code 0, table visible with "Valid Table" title
    Evidence: .sisyphus/evidence/task-2-valid-title.{ext}
  ```

- [x] 3. Add npm audit to CI Workflow

  **What to do**:
  - Read `.github/workflows/ci.yml`
  - Add new step after "Install dependencies": `npm audit --audit-level=moderate`
  - Document in README or CONTRIBUTING.md that audit runs on PRs
  - Consider adding `--audit-level=high` for stricter blocking

  **Must NOT do**:
  - Do NOT modify other workflow steps
  - Do NOT skip existing CI jobs

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file modification, no complex logic

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `.github/workflows/ci.yml:1-43` - Existing CI structure
  - `npm audit` official docs for `--audit-level` flag options

  **Acceptance Criteria**:
  - [ ] CI workflow includes `npm audit` step
  - [ ] Audit level set to `moderate` (or `high`)
  - [ ] Step runs after `npm ci` and before build steps
  - [ ] Audit failures block the CI pipeline

  **QA Scenarios**:

  ```
  Scenario: CI fails when moderate vulnerabilities present
    Tool: Bash (git + gh)
    Preconditions: Clean git state, existing CI passing
    Steps:
      1. Modify a devDependency to a version with known moderate CVE
      2. Commit and push
      3. Check CI status on the commit
    Expected Result: CI run fails at audit step
    Evidence: .sisyphus/evidence/task-3-audit-fail.{ext}

  Scenario: CI passes when no vulnerabilities present
    Tool: Bash
    Preconditions: Clean state, all dependencies clean
    Steps:
      1. Run `npm audit` locally
      2. Verify exit code is 0 (no vulnerabilities)
    Expected Result: Exit code 0, no audit output showing vulnerabilities
    Evidence: .sisyphus/evidence/task-3-audit-pass.{ext}
  ```

