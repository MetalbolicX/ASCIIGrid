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
  @val @scope("process") external nextTick: (() => unit) => unit = "nextTick"

  module Stdout = {
    @module("node:process") @scope("stdout")
    external write: string => bool = "write"

    /** Write string with callback invoked on drain. Returns false when buffer is full. */
    @module("node:process") @scope("stdout")
    external writeWithCallback: (string, () => unit) => bool = "write"

    /** Register a one-time callback for the drain event (auto-removes after firing). */
    @module("node:process") @scope("stdout")
    external onceDrain: (() => unit) => unit = "once"
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

module Readline = {
  /** Opaque type for Node.js readline interface. */
  type interface

  type config = {
    input: Stdio.readableStream,
    crlfDelay?: int,
    terminal?: bool,
  }

  @module("node:readline/promises")
  external createInterface: config => interface = "createInterface"

  /** Register a handler for the 'line' event — receives each line as it's read. */
  @send
  external onLine: (interface, string, (string => unit)) => interface = "on"

  /** Register a handler for the 'close' event — fired when input is exhausted. */
  @send
  external onClose: (interface, string, (() => unit)) => interface = "on"

  /**
   * Register a handler for the 'error' event.
   * Note: We name it onError2 to avoid conflict with the existing onError (which
   * also takes (interface, string, callback) but for a different callback arity).
   */
  @send
  external onError2: (interface, string, ((string) => unit)) => interface = "on"

  /** Close the readline interface, cleaning up resources. */
  @send
  external close: interface => unit = "close"
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
