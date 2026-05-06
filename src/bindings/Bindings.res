/**
 * Centralized typed bindings to Node.js runtime APIs.
 *
 * Each module groups related bindings from a built-in Node module.
 * Using typed `external` declarations with ReScript -> JS interop.
 *
 * @module Bindings
 */

module Fs = {
  @module("node:fs") external readFileSync: ('source, string) => string = "readFileSync"
  @module("node:fs") external writeFileSync: (string, string) => unit = "writeFileSync"
}

module Process = {
  @module("node:process") external argv: array<string> = "argv"
  @module("node:process") external exit: int => unit = "exit"

  module Stdout = {
    @module("node:process") @scope("stdout")
    external write: string => bool = "write"
  }

  module Stderr = {
    @module("node:process") @scope("stderr")
    external write: string => bool = "write"
  }
}

module Stdio = {
  /** Opaque type for Node.js ReadableStream — prevents misuse with JSON.t. */
  type readableStream

  @module("node:process") external stdin: readableStream = "stdin"
  @module("node:stream/consumers")
  external readAll: readableStream => promise<string> = "text"
}

module Util = {
  @unboxed
  type defaultValue =
    | String(string)
    | Bool(bool)

  type flagConfig = {
    @as("type") type_: string,
    short?: string,
    default?: defaultValue,
    multiple?: bool,
  }

  type cliOptions = {
    help?: bool,
    version?: bool,
    input?: string,
    format?: string,
    title?: string,
    padding?: string,
    @as("no-header") noHeader?: bool,
    spreadsheet?: bool,
    align?: bool,
    theme?: string,
    output?: string,
    rich?: bool,
    @as("theme-file") themeFile?: string,
  }

  type parseResults = {
    values: cliOptions,
    positionals: array<string>,
  }

  type parseConfig = {
    args: array<string>,
    options: dict<flagConfig>,
    strict?: bool,
    allowPositionals?: bool,
    tokens?: bool,
  }

  @module("node:util")
  external parseArgs: parseConfig => parseResults = "parseArgs"
}
