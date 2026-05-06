# Contributing to ASCIIGrid

Thank you for your interest in contributing!

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/MetalbolicX/ASCIIGrid.git
   cd ASCIIGrid
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Build the project:
   ```bash
   npm run res:build
   npm run bundle
   ```

## Development Workflow

### Watch Mode
```bash
npm run res:dev
```
Runs ReScript in watch mode, recompiling on file changes.

### Building
```bash
npm run res:build   # Compile ReScript
npm run bundle      # Bundle with Rolldown
```

### Testing

**Unit tests (ReScript):**
```bash
npm run res:test
```

**CLI integration tests:**
```bash
npm run test:cli
```

**All tests:**
```bash
npm run res:test && npm run test:cli
```

## Code Style

- Follow ReScript conventions used in the codebase
- Use descriptive variable names
- Add comments for complex logic
- Keep functions small and focused

## Project Structure

```
src/
├── Cli/
│   └── CliEntry.res      # CLI entry point and argument parsing
├── bindings/
│   └── Bindings.res      # Node.js bindings
├── grid/
│   ├── AsciiGrid.res     # Main rendering logic
│   ├── AsciiGridAdapters.res
│   ├── AsciiGridLayout.res
│   ├── AsciiGridOptions.res
│   ├── AsciiGridRenderers.res
│   ├── AsciiGridTheme.res
│   └── AsciiGridTransformers.res
├── Logger.res            # Logging module
└── Main.res              # Main module (example usage)

test/
├── cli/
│   └── Cli_test.mjs      # CLI integration tests (Node.js)
└── res/
    └── grid/
        └── AsciiGrid_test.res  # Unit tests (ReScript)
```

## Versioning Policy

- Follows [Semantic Versioning](https://semver.org/)
- Uses [Conventional Commits](https://www.conventionalcommits.org/) for changelog generation
- Version bumps via `npm version patch|minor|major`

## Release Process

1. Ensure all tests pass
2. Update version in `package.json`
3. Create git tag: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions will build and create a release

## Pull Requests

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure tests pass
5. Submit a pull request

## Reporting Issues

Please report issues on [GitHub Issues](https://github.com/MetalbolicX/ASCIIGrid/issues) with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Node.js version