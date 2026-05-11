# Draft: ASCIIGrid Production Readiness Plan

## Interview Summary
- **User's Goal**: Address production readiness gaps identified in codebase review
- **Scope**: Security hardening (ANSI sanitization), CI improvements (CVE scanning, coverage), Configuration validation (fail-fast)

## Research Findings
- ASCIIGrid is a ReScript CLI tool rendering ASCII tables
- Current: JSON/NDJSON streaming, unit tests via retest, CLI integration tests
- CI runs: res:build, res:format --check, bundle, res:test, test:cli

## Technical Decisions
- ANSI sanitization: Strip/validate escape sequences in user text (title, any string input to grid)
- CVE scanning: npm audit or snyk integration into CI
- Coverage: Add threshold via retest coverage report or nyc
- Fail-fast: Validate required CLI args on startup

## Scope Boundaries
- IN: All 4 improvements, CI workflow updates
- EXCLUDE: Breaking changes to AsciiGrid core rendering logic

## Open Questions
- What ANSI escape sequences should be stripped? (ESC[? only, or all non-printable chars?)
- Preferred CVE scanner: npm audit (builtin) or snyk (more comprehensive)?
- Coverage threshold target: 80%? 70%?
