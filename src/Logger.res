/**
 * Simple logging module for ASCIIGrid CLI.
 * Supports verbose mode and DEBUG environment variable.
 *
 * @module Logger
 */
type level = Error | Warn | Info | Debug

let isVerbose = ref(false)
let isDebug = ref(false)

@val @scope("JSON")
external jsonStringify: dict<string> => string = "stringify"

let init = (~verbose: bool): unit => {
  isVerbose.contents = verbose
  isDebug.contents =
    Dict.get(Bindings.Env.env, "DEBUG")->Option.map(v => v != "")->Option.getOr(false)
}

let log = (level: level, msg: string): unit => {
  let shouldLog = switch level {
  | Error => true
  | Warn => isVerbose.contents
  | Info => isVerbose.contents
  | Debug => isDebug.contents
  }

  if shouldLog {
    let levelText = switch level {
    | Error => "error"
    | Warn => "warn"
    | Info => "info"
    | Debug => "debug"
    }
    let ts = Date.now()->Float.toString
    let payload = Dict.make()
    Dict.set(payload, "level", levelText)
    Dict.set(payload, "ts", ts)
    Dict.set(payload, "msg", msg)
    Bindings.Process.Stderr.write(jsonStringify(payload) ++ "\n")->ignore
  }
}

let error = (msg: string): unit => log(Error, msg)
let warn = (msg: string): unit => log(Warn, msg)
let info = (msg: string): unit => log(Info, msg)
let debug = (msg: string): unit => log(Debug, msg)
