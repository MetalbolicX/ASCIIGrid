# ASCIIGrid

Render beautiful ASCII tables from JSON/NDJSON in your terminal.

## Installation

```bash
npm install -g asciigrid
```

Requires Node.js >= 22.0.0

## Quick Start

**From stdin:**
```bash
echo '[["Name","Age"],["Alice","30"],["Bob","25"]]' | asciigrid
```

**From file:**
```bash
asciigrid --input data.json
```

**NDJSON streaming:**
```bash
cat records.ndjson | asciigrid --format ndjson
```

## Features

- **Multiple input formats**: JSON arrays, NDJSON (newline-delimited JSON)
- **Streaming support**: Process large NDJSON files line-by-line without loading into memory
- **Spreadsheet mode**: Add column letters (A, B, C...) and row numbers
- **Numeric alignment**: Right-align numbers for better readability
- **Theme support**: MySQL, Unicode, or Oracle-style borders
- **Rich type preservation**: Keep numbers as numbers, booleans as booleans

## CLI Reference

| Flag | Description | Default |
|------|-------------|---------|
| `-i, --input <file>` | Input file path | stdin |
| `-f, --format <fmt>` | Input format: `json` or `ndjson` | `json` |
| `-t, --title <text>` | Table title | - |
| `-p, --padding <n>` | Cell padding (spaces on each side) | `1` |
| `-H, --no-header` | Disable header separator | - |
| `-s, --spreadsheet` | Enable spreadsheet labels | - |
| `-a, --align` | Right-align numeric values | - |
| `-T, --theme <name>` | Border theme: `mysql`, `unicode`, `oracle` | `mysql` |
| `-o, --output <file>` | Write output to file | stdout |
| `-v, --verbose` | Enable verbose output | - |
| `--timeout <sec>` | Timeout for stdin (0 = disabled) | `0` |
| `--max-rows <n>` | Maximum rows to process | `100000` |
| `--rich` | Preserve JSON value types | - |
| `-h, --help` | Show help | - |
| `--version` | Show version | - |

## Examples

### Basic Table
```bash
echo '[["Name","City"],["Alice","NYC"],["Bob","LA"]]' | asciigrid
```
```
+-------+-------+
| Name  | City  |
+-------+-------+
| Alice | NYC   |
| Bob   | LA    |
+-------+-------+
```

### With Title
```bash
echo '[["Name","Age"],["Alice","30"],["Bob","25"]]' | asciigrid --title "Users"
```
```
+--------------------+
|       Users        |
+-------+-----+------+
| Name  | Age | City |
+-------+-----+------+
| Alice | 30  | NYC  |
| Bob   | 25  | LA   |
+-------+-----+------+
```

### Spreadsheet Mode
```bash
echo '[["Name","Age"],["Alice","30"]]' | asciigrid --spreadsheet
```
```
+---+-------+-----+------+
|   | A     | B   | C    |
+---+-------+-----+------+
| 0 | Name  | Age | City |
+---+-------+-----+------+
| 1 | Alice | 30  | NYC  |
+---+-------+-----+------+
```

### Unicode Theme
```bash
echo '[["Name"],["Alice"]]' | asciigrid --theme unicode
```
```
╔═══════╗
║ Name  ║
╠═══════╣
║ Alice ║
╚═══════╝
```

### NDJSON Streaming
```bash
echo '{"name":"Alice","age":30}
{"name":"Bob","age":25}' | asciigrid --format ndjson
```

### Numeric Alignment
```bash
echo '[["Item","Price"],["Apple",42],["Banana",7]]' | asciigrid --align
```
```
+--------+-------+
| Item   | Price |
+--------+-------+
| Apple  |    42 |
| Banana |     7 |
+--------+-------+
```

### Rich Type Preservation
```bash
echo '[["value"],[30],[22.5],[true],[null]]' | asciigrid --rich
```
```
+-------+-------+
| value |       |
+-------+-------+
|    30 |       |
|  22.5 |       |
|  true |       |
|       |       |
+-------+-------+
```

### Timeout
```bash
# Will timeout after 5 seconds of no input
cat | asciigrid --timeout 5
```

### Max Rows Guardrail
```bash
# Reject input larger than 10k rows
cat records.ndjson | asciigrid --format ndjson --max-rows 10000
```

## Input Formats

### JSON Array
```json
[["Name", "Age"], ["Alice", "30"], ["Bob", "25"]]
```

### JSON Array of Objects
```json
[{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]
```

### NDJSON
```
{"name": "Alice", "age": 30}
{"name": "Bob", "age": 25}
```

## Exit Codes

- `0`: Success
- `1`: Invalid argument (format, theme, etc.)
- `2`: Parse error (invalid JSON/NDJSON)
- `3`: Render error (invalid data shape)
- `4`: Unexpected error
- `124`: Timeout
- `130`: Interrupted (SIGINT)
- `143`: Terminated (SIGTERM)

## License

MIT
