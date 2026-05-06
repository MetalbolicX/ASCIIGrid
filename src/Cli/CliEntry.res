type cliError = (int, string)

// Both bind to Math.trunc. Float variant is used for the isInteger check
// (needs float == float); int variant avoids the 32-bit |0 truncation of
// Float.toInt so large integer-valued JSON numbers survive round-trip.
@val @scope("Math")
external mathTruncF: float => float = "trunc"

@val @scope("Math")
external mathTruncI: float => int = "trunc"

@val @scope("JSON")
external jsonParseUnsafe: string => JSON.t = "parse"

let writeStdout = (text: string): unit => {
  Bindings.Process.Stdout.write(text)->ignore
}

let writeStderr = (text: string): unit => {
  Bindings.Process.Stderr.write(text)->ignore
}

let helpText =
  "ASCIIGrid - Render ASCII tables from JSON/NDJSON\n\n"
  ++ "Usage:\n"
  ++ "  ASCIIGrid [options] [file]\n\n"
  ++ "Options:\n"
  ++ "  -i, --input <file>     Input file path (default: stdin)\n"
  ++ "  -f, --format <fmt>     Input format: json | ndjson (default: json)\n"
  ++ "  -t, --title <text>     Table title\n"
  ++ "  -p, --padding <n>      Cell padding (default: 1)\n"
  ++ "  -H, --no-header        Disable header separator\n"
  ++ "  -s, --spreadsheet      Enable spreadsheet labels\n"
  ++ "  -a, --align            Right-align numeric values\n"
  ++ "  -T, --theme <name>     mysql | unicode | oracle (default: mysql)\n"
  ++ "  -o, --output <file>    Write output file (default: stdout)\n"
  ++ "      --rich             Preserve JSON value types\n"
  ++ "  -h, --help             Show help\n"
  ++ "      --version          Show version\n"

let versionText = "ASCIIGrid 0.1.0\n"

let parseArgs = (): Bindings.Util.parseResults => {
  let options = Dict.make()
  let setOption = (key: string, config: Bindings.Util.flagConfig) => Dict.set(options, key, config)

  setOption("input", {type_: "string", short: "i"})
  setOption("format", {type_: "string", short: "f", default: Bindings.Util.String("json")})
  setOption("title", {type_: "string", short: "t"})
  setOption("padding", {type_: "string", short: "p", default: Bindings.Util.String("1")})
  setOption("no-header", {type_: "boolean", short: "H", default: Bindings.Util.Bool(false)})
  setOption("spreadsheet", {type_: "boolean", short: "s", default: Bindings.Util.Bool(false)})
  setOption("align", {type_: "boolean", short: "a", default: Bindings.Util.Bool(false)})
  setOption("theme", {type_: "string", short: "T", default: Bindings.Util.String("mysql")})
  setOption("output", {type_: "string", short: "o"})
  setOption("rich", {type_: "boolean", default: Bindings.Util.Bool(false)})
  setOption("help", {type_: "boolean", short: "h", default: Bindings.Util.Bool(false)})
  setOption("version", {type_: "boolean", default: Bindings.Util.Bool(false)})

  let args = Bindings.Process.argv->Array.slice(~start=2)
  Bindings.Util.parseArgs({args, options, allowPositionals: true})
}

let parsePadding = (rawPadding: option<string>): int => {
  switch rawPadding {
  | None => 1
  | Some(value) =>
    switch Int.fromString(value) {
    | Some(n) => if n >= 0 { n } else { 0 }
    | None => 1
    }
  }
}

let parseTheme = (rawTheme: option<string>): result<AsciiGridTheme.t, cliError> => {
  let normalized = rawTheme->Option.getOr("mysql")->String.toLowerCase
  switch normalized {
  | "mysql" => Ok(AsciiGridTheme.mysql)
  | "unicode" => Ok(AsciiGridTheme.unicode)
  | "oracle" => Ok(AsciiGridTheme.oracle)
  | _ => Error((1, "Invalid theme: " ++ normalized ++ ". Use mysql|unicode|oracle"))
  }
}

let parseFormat = (rawFormat: option<string>): result<string, cliError> => {
  let normalized = rawFormat->Option.getOr("json")->String.toLowerCase
  switch normalized {
  | "json" => Ok("json")
  | "ndjson" => Ok("ndjson")
  | _ => Error((1, "Invalid format: " ++ normalized ++ ". Use json|ndjson"))
  }
}

let stringifyJsonCell = (value: JSON.t): string =>
  switch JSON.Decode.string(value) {
  | Some(s) => s
  | None =>
    switch JSON.Decode.float(value) {
    | Some(n) => Float.toString(n)
    | None =>
      switch JSON.Decode.bool(value) {
      | Some(true) => "true"
      | Some(false) => "false"
      | None =>
        switch JSON.Decode.null(value) {
        | Some(_) => ""
        | None => ""
        }
      }
    }
  }

let jsonToCellValue = (value: JSON.t): AsciiGridAdapters.cellValue =>
  switch JSON.Decode.string(value) {
  | Some(s) => AsciiGridAdapters.CellString(s)
  | None =>
    switch JSON.Decode.float(value) {
    | Some(n) =>
      if Float.isFinite(n) && mathTruncF(n) == n {
        AsciiGridAdapters.CellInt(mathTruncI(n))
      } else {
        AsciiGridAdapters.CellFloat(n)
      }
    | None =>
      switch JSON.Decode.bool(value) {
      | Some(b) => AsciiGridAdapters.CellBool(b)
      | None => AsciiGridAdapters.CellNull
      }
    }
  }

let buildRichRow = (obj: dict<JSON.t>): AsciiGridAdapters.richRowObject =>
  obj->Dict.toArray->Array.reduce(Dict.make(), (acc, (key, value)) => {
    Dict.set(acc, key, jsonToCellValue(value))
    acc
  })

let buildStringRow = (obj: dict<JSON.t>): AsciiGridAdapters.rowObject =>
  obj->Dict.toArray->Array.reduce(Dict.make(), (acc, (key, value)) => {
    Dict.set(acc, key, stringifyJsonCell(value))
    acc
  })

let parseJsonInput = (
  ~raw: string,
  ~rich: bool,
  ~options: AsciiGridOptions.t,
): result<result<string, string>, cliError> => {
  let parsedResult: result<JSON.t, cliError> =
    try {
      Ok(jsonParseUnsafe(raw))
    } catch {
    | _ => Error((2, "Invalid JSON input"))
    }

  switch parsedResult {
  | Error(err) => Error(err)
  | Ok(parsed) =>
    switch JSON.Decode.array(parsed) {
  | None => Error((2, "JSON input must be an array"))
  | Some(items) =>
    if items->Array.length == 0 {
      Ok(AsciiGrid.render([], options))
    } else {
      switch items->Belt.Array.get(0) {
      | None => Ok(AsciiGrid.render([], options))
      | Some(first) =>
        if JSON.Decode.array(first)->Option.isSome {
          if rich {
            let matrix: array<array<AsciiGridAdapters.cellValue>> =
              items->Array.map(row =>
                switch JSON.Decode.array(row) {
                | Some(cells) => cells->Array.map(jsonToCellValue)
                | None => [AsciiGridAdapters.CellNull]
                }
              )
            Ok(AsciiGrid.renderRich(matrix, options))
          } else {
            let matrix: array<array<string>> =
              items->Array.map(row =>
                switch JSON.Decode.array(row) {
                | Some(cells) => cells->Array.map(stringifyJsonCell)
                | None => [""]
                }
              )
            Ok(AsciiGrid.render(matrix, options))
          }
        } else if JSON.Decode.object(first)->Option.isSome {
          if rich {
            let rows: array<AsciiGridAdapters.richRowObject> =
              items->Array.map(row =>
                switch JSON.Decode.object(row) {
                | Some(obj) => buildRichRow(obj)
                | None => Dict.make()
                }
              )
            Ok(AsciiGrid.renderWithRichObjects(rows, options))
          } else {
            let rows: array<AsciiGridAdapters.rowObject> =
              items->Array.map(row =>
                switch JSON.Decode.object(row) {
                | Some(obj) => buildStringRow(obj)
                | None => Dict.make()
                }
              )
            Ok(AsciiGrid.renderWithObjects(rows, options))
          }
        } else {
          Error((2, "JSON root array must contain arrays or objects"))
        }
      }
    }
    }
  }
}

let parseNdjsonInput = (
  ~raw: string,
  ~rich: bool,
  ~options: AsciiGridOptions.t,
): result<result<string, string>, cliError> => {
  let lines = raw->String.split("\n")->Array.map(String.trim)->Belt.Array.keep(line => line != "")

  if lines->Array.length == 0 {
    Ok(AsciiGrid.render([], options))
  } else if rich {
    let rowsResult: result<array<AsciiGridAdapters.richRowObject>, cliError> =
      lines->Array.reduce(Ok([]), (acc, line) =>
        switch acc {
        | Error(err) => Error(err)
        | Ok(rows) =>
          let parsedResult: result<JSON.t, cliError> =
            try {
              Ok(jsonParseUnsafe(line))
            } catch {
            | _ => Error((2, "Invalid NDJSON line: " ++ line))
            }
          switch parsedResult {
          | Error(err) => Error(err)
          | Ok(parsed) =>
            switch JSON.Decode.object(parsed) {
            | None => Error((2, "NDJSON lines must be JSON objects"))
            | Some(obj) => {
                rows->Array.push(buildRichRow(obj))
                Ok(rows)
              }
            }
          }
        }
      )

    switch rowsResult {
    | Ok(rows) => Ok(AsciiGrid.renderWithRichObjects(rows, options))
    | Error(err) => Error(err)
    }
  } else {
    let rowsResult: result<array<AsciiGridAdapters.rowObject>, cliError> =
      lines->Array.reduce(Ok([]), (acc, line) =>
        switch acc {
        | Error(err) => Error(err)
        | Ok(rows) =>
          let parsedResult: result<JSON.t, cliError> =
            try {
              Ok(jsonParseUnsafe(line))
            } catch {
            | _ => Error((2, "Invalid NDJSON line: " ++ line))
            }
          switch parsedResult {
          | Error(err) => Error(err)
          | Ok(parsed) =>
            switch JSON.Decode.object(parsed) {
            | None => Error((2, "NDJSON lines must be JSON objects"))
            | Some(obj) => {
                rows->Array.push(buildStringRow(obj))
                Ok(rows)
              }
            }
          }
        }
      )

    switch rowsResult {
    | Ok(rows) => Ok(AsciiGrid.renderWithObjects(rows, options))
    | Error(err) => Error(err)
    }
  }
}

let readInput = (inputPath: option<string>, positionals: array<string>): promise<string> => {
  let effectiveInput =
    switch inputPath {
    | Some(path) => Some(path)
    | None => Belt.Array.get(positionals, 0)
    }

  switch effectiveInput {
  | Some(path) =>
    let content = Bindings.Fs.readFileSync(path, "utf8")
    Promise.resolve(content)
  | None => Bindings.Stdio.readAll(Bindings.Stdio.stdin)
  }
}

let run = (): promise<unit> => {
  let parsed = parseArgs()
  let values = parsed.values

  if values.help->Option.getOr(false) {
    writeStdout(helpText)
    Bindings.Process.exit(0)
    Promise.resolve()
  } else if values.version->Option.getOr(false) {
    writeStdout(versionText)
    Bindings.Process.exit(0)
    Promise.resolve()
  } else {
    switch parseFormat(values.format) {
    | Error((code, message)) => {
        writeStderr(message ++ "\n")
        Bindings.Process.exit(code)
        Promise.resolve()
      }
    | Ok(format) =>
      switch parseTheme(values.theme) {
      | Error((code, message)) => {
          writeStderr(message ++ "\n")
          Bindings.Process.exit(code)
          Promise.resolve()
        }
      | Ok(theme) => {
          let options: AsciiGridOptions.t = {
            title: values.title,
            padding: parsePadding(values.padding),
            header: !(values.noHeader->Option.getOr(false)),
            spreadsheet: values.spreadsheet->Option.getOr(false),
            align: values.align->Option.getOr(false),
            theme: theme,
          }

          Promise.then(
            readInput(values.input, parsed.positionals),
            raw => {
              let parsedRender =
                switch format {
                | "json" => parseJsonInput(~raw, ~rich=values.rich->Option.getOr(false), ~options)
                | "ndjson" => parseNdjsonInput(~raw, ~rich=values.rich->Option.getOr(false), ~options)
                | _ => Error((1, "Unsupported format"))
                }

              switch parsedRender {
              | Error((code, message)) => {
                  writeStderr(message ++ "\n")
                  Bindings.Process.exit(code)
                }
              | Ok(renderResult) =>
                switch renderResult {
                | Error(message) => {
                    writeStderr(message ++ "\n")
                    Bindings.Process.exit(3)
                  }
                | Ok(table) =>
                  switch values.output {
                  | Some(path) => Bindings.Fs.writeFileSync(path, table ++ "\n")
                  | None => writeStdout(table ++ "\n")
                  }
                }
              }

              Promise.resolve()
            },
          )
          ->Promise.catch(_err => {
            writeStderr("Unexpected error\n")
            Bindings.Process.exit(4)
            Promise.resolve()
          })
        }
      }
    }
  }
}

let _ = run()->ignore
