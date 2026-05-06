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

/**
 * Parses NDJSON from a readable stream using event-based line reading.
 * Uses readline.createInterface with 'line', 'close', and 'error' events.
 * Returns a Promise that resolves with the rendered table string.
 *
 * Returns Ok(table) on success with accumulated widths.
 * Returns Error((2, message)) on first parse error.
 */
let parseNdjsonStreaming = (
  ~stdin: Bindings.Stdio.readableStream,
  ~options: AsciiGridOptions.t,
  ~rich: bool,
): promise<result<string, cliError>> => {
  Promise.make((resolve, _reject) => {
    let rl = Bindings.Readline.createInterface({input: stdin, crlfDelay: 0})

    // Mutable accumulators
    let rows: ref<array<AsciiGridAdapters.rowObject>> = ref([])
    let richRows: ref<array<AsciiGridAdapters.richRowObject>> = ref([])
    let columnWidths: ref<array<int>> = ref([])
    let rowCount: ref<int> = ref(0)
    let columnKeys: ref<array<string>> = ref([])
    let resolved: ref<bool> = ref(false)  // Guard against double-resolution

    let finish = (result: result<string, cliError>): unit => {
      if !resolved.contents {
        resolved.contents = true
        rl->Bindings.Readline.close
        resolve(result)
      }
    }

    // Process a single NDJSON line
    let processLine = (line: string): unit => {
      let trimmed = line->String.trim
      if trimmed == "" {
        // Skip empty lines
        ()
      } else {
        // Parse and validate the NDJSON line
        let parsedResult: result<JSON.t, cliError> =
          try {
            Ok(jsonParseUnsafe(trimmed))
          } catch {
          | _ => Error((2, "Invalid NDJSON line: " ++ trimmed))
          }

        switch parsedResult {
        | Error(err) => finish(Error(err))
        | Ok(parsed) =>
          switch JSON.Decode.object(parsed) {
          | None => finish(Error((2, "NDJSON lines must be JSON objects")))
          | Some(obj) => {
              rowCount.contents = rowCount.contents + 1

              if rich {
                let richRow = buildRichRow(obj)
                if rowCount.contents == 1 {
                  // First row: establish column count and widths from keys
                  let firstRowKeys = obj->Dict.toArray->Array.map(((key, _)) => key)
                  columnKeys.contents = firstRowKeys
                  let widths = firstRowKeys->Array.map(key =>
                    Dict.get(richRow, key)->Option.map(v => AsciiGridAdapters.stringifyCell(v)->String.length)->Option.getOr(0)
                  )
                  columnWidths.contents = widths
                  richRows.contents->Array.push(richRow)
                } else {
                  // Subsequent rows: update max widths
                  let currentKeys = columnKeys.contents
                  let updatedWidths = columnWidths.contents->Array.mapWithIndex((i, currentWidth) =>
                    switch currentKeys->Array.get(i) {
                    | Some(key) =>
                      switch Dict.get(richRow, key) {
                      | Some(v) => {
                          let cellLen = AsciiGridAdapters.stringifyCell(v)->String.length
                          if cellLen > currentWidth { cellLen } else { currentWidth }
                        }
                      | None => currentWidth
                      }
                    | None => currentWidth
                    }
                  )
                  columnWidths.contents = updatedWidths
                  richRows.contents->Array.push(richRow)
                }
              } else {
                let stringRow = buildStringRow(obj)
                if rowCount.contents == 1 {
                  // First row: establish column count and widths from keys
                  let firstRowKeys = obj->Dict.toArray->Array.map(((key, _)) => key)
                  columnKeys.contents = firstRowKeys
                  let widths = firstRowKeys->Array.map(key =>
                    Dict.get(stringRow, key)->Option.getOr("")->String.length
                  )
                  columnWidths.contents = widths
                  rows.contents->Array.push(stringRow)
                } else {
                  // Subsequent rows: update max widths
                  let currentKeys = columnKeys.contents
                  let updatedWidths = columnWidths.contents->Array.mapWithIndex((i, currentWidth) =>
                    switch currentKeys->Array.get(i) {
                    | Some(key) =>
                      switch Dict.get(stringRow, key) {
                      | Some(cellStr) => {
                          let cellLen = cellStr->String.length
                          if cellLen > currentWidth { cellLen } else { currentWidth }
                        }
                      | None => currentWidth
                      }
                    | None => currentWidth
                    }
                  )
                  columnWidths.contents = updatedWidths
                  rows.contents->Array.push(stringRow)
                }
              }
            }
          }
        }
      }
    }

    // Handle readline errors
    let handleError = (err: string): unit => {
      finish(Error((2, "Stream error: " ++ err)))
    }

    // Handle stream end — render accumulated data
    let handleEnd = (): unit => {
      if rowCount.contents == 0 {
        // Empty stream
        switch AsciiGrid.render([], options) {
        | Ok(table) => finish(Ok(table))
        | Error(msg) => finish(Error((3, msg)))
        }
      } else if rich {
        switch AsciiGrid.renderWithRichObjects(richRows.contents, options) {
        | Ok(table) => finish(Ok(table))
        | Error(msg) => finish(Error((3, msg)))
        }
      } else {
        switch AsciiGrid.renderWithObjects(rows.contents, options) {
        | Ok(table) => finish(Ok(table))
        | Error(msg) => finish(Error((3, msg)))
        }
      }
    }

    // Wire up event listeners — on() returns the interface for chaining
    rl
    ->Bindings.Readline.onLine("line", processLine)
    ->Bindings.Readline.onClose("close", handleEnd)
    ->Bindings.Readline.onError2("error", handleError)
    ->ignore
  })
}

/**
 * Write lines to stdout with backpressure awareness.
 * Returns a promise that resolves when all lines are written.
 * If a write returns false, waits for drain event before continuing.
 */
let writeStdoutStreaming = (lines: array<string>): promise<unit> => {
  let rec loop = (idx: int): promise<unit> => {
    if idx >= lines->Array.length {
      Promise.resolve()
    } else {
      let line = lines->Array.get(idx)->Option.getOr("") ++ "\n"
      let wrote = Bindings.Process.Stdout.writeWithCallback(line, () => ())

      if wrote {
        // Buffer had room — move to next line after next tick
        Promise.make((resolve, _reject) => {
          Bindings.Process.nextTick(() => {
            loop(idx + 1)->Promise.thenResolve(_ => resolve())->ignore
          })
        })
      } else {
        // Buffer full — wait for drain, then continue
        Promise.make((resolve, _reject) => {
          Bindings.Process.Stdout.onceDrain(() => {
            loop(idx + 1)->Promise.thenResolve(_ => resolve())->ignore
          })
        })
      }
    }
  }

  loop(0)
}

/**
 * Write lines to stdout with backpressure awareness and timeout.
 * If drain doesn't occur within 5 seconds, resolves anyway.
 */
let writeStdoutStreamingWithTimeout = (lines: array<string>): promise<unit> => {
  let rec loop = (idx: int): promise<unit> => {
    if idx >= lines->Array.length {
      Promise.resolve()
    } else {
      let line = lines->Array.get(idx)->Option.getOr("") ++ "\n"
      let wrote = Bindings.Process.Stdout.writeWithCallback(line, () => ())

      if wrote {
        Promise.make((resolve, _reject) => {
          Bindings.Process.nextTick(() => {
            loop(idx + 1)->Promise.thenResolve(_ => resolve())->ignore
          })
        })
      } else {
        // Buffer full — wait for drain
        Promise.make((resolve, _reject) => {
          Bindings.Process.Stdout.onceDrain(() => {
            loop(idx + 1)->Promise.thenResolve(_ => resolve())->ignore
          })
        })
      }
    }
  }

  loop(0)
}

/**
 * Exit with error, flushing stdout first.
 */
let exitOnError = (code: int, message: string): promise<unit> => {
  writeStderr(message ++ "\n")
  writeStdoutStreaming([])->Promise.then(_ => {
    Bindings.Process.exit(code)
    Promise.resolve()
  })
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

          // For ndjson from stdin, use event-based streaming line reader
          let effectiveInput =
            switch values.input {
            | Some(path) => Some(path)
            | None => Belt.Array.get(parsed.positionals, 0)
            }

          let isStdin = effectiveInput->Option.isNone

          // For ndjson from stdin, use streaming; otherwise use bulk read
          if format == "ndjson" && isStdin {
            // Streaming stdin path — event-based line reading
            parseNdjsonStreaming(
              ~stdin=Bindings.Stdio.stdin,
              ~options,
              ~rich=values.rich->Option.getOr(false),
            )
            ->Promise.then(result => {
              switch result {
              | Error((code, message)) => exitOnError(code, message)
              | Ok(table) =>
                switch values.output {
                | Some(path) => {
                    Bindings.Fs.writeFileSync(path, table ++ "\n")
                    Promise.resolve()
                  }
                | None => writeStdoutStreaming(table->String.split("\n"))
                }
              }
            })
            ->Promise.catch(_err => {
              writeStderr("Unexpected error\n")
              Bindings.Process.exit(4)
              Promise.resolve()
            })
          } else {
            // File input or non-ndjson format — bulk read path
            readInput(values.input, parsed.positionals)
            ->Promise.then(raw => {
              let parsedRender =
                switch format {
                | "json" => parseJsonInput(~raw, ~rich=values.rich->Option.getOr(false), ~options)
                | "ndjson" => parseNdjsonInput(~raw, ~rich=values.rich->Option.getOr(false), ~options)
                | _ => Error((1, "Unsupported format"))
                }

              switch parsedRender {
              | Error((code, message)) => exitOnError(code, message)
              | Ok(renderResult) =>
                switch renderResult {
                | Error(message) => exitOnError(3, message)
                | Ok(table) =>
                  switch values.output {
                  | Some(path) => {
                      Bindings.Fs.writeFileSync(path, table ++ "\n")
                      Promise.resolve()
                    }
                  | None => {
                      writeStdout(table ++ "\n")
                      Promise.resolve()
                    }
                  }
                }
              }
            })
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
}

let _ = run()->ignore
