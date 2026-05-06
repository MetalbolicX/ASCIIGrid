/**
 * Simple logging module for ASCIIGrid CLI.
 * Supports verbose mode and DEBUG environment variable.
 *
 * @module Logger
 */

type level = Error | Warn | Info | Debug

let isVerbose = ref(false)
let isDebug = ref(false)

let init = (~verbose: bool): unit => {
  isVerbose.contents = verbose
}

let log = (level: level, msg: string): unit => {
  let shouldLog = switch level {
  | Error => true
  | Warn => isVerbose.contents
  | Info => isVerbose.contents
  | Debug => isDebug.contents
  }

  if shouldLog {
    let prefix = switch level {
    | Error => "ERROR"
    | Warn => "WARN"
    | Info => "INFO"
    | Debug => "DEBUG"
    }
    Bindings.Process.Stderr.write(`[${prefix}] ${msg}\n`)->ignore
  }
}

let error = (msg: string): unit => log(Error, msg)
let warn = (msg: string): unit => log(Warn, msg)
let info = (msg: string): unit => log(Info, msg)
let debug = (msg: string): unit => log(Debug, msg)