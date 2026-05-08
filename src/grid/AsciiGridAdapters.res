type rowObject = dict<string>

/**
 * Represents any cell value accepted by the rich API.
 * Mirrors the TS `CellValue = string | number | boolean | null | undefined` union.
 * CellNull covers both null and undefined — both render as empty string.
 */
type cellValue =
  | CellString(string)
  | CellInt(int)
  | CellFloat(float)
  | CellBool(bool)
  | CellNull

type richRowObject = dict<cellValue>

let stringifyCell = (v: cellValue): string =>
  switch v {
  | CellString(s) => s
  | CellInt(i) => Int.toString(i)
  | CellFloat(f) => Float.toString(f)
  | CellBool(b) =>
    if b {
      "true"
    } else {
      "false"
    }
  | CellNull => ""
  }

let normalizeMatrix = (rows: array<array<string>>): array<array<string>> => rows

let normalizeRichMatrix = (rows: array<array<cellValue>>): array<array<string>> =>
  rows->Array.map(row => row->Array.map(stringifyCell))

// Polymorphic key extractor — works for any dict<'a> so both rowObject and
// richRowObject share a single implementation.
let extractKeysOrdered = (rows: array<dict<'a>>): array<string> => {
  let seen = Dict.make()
  let keys = Belt.Array.make(0, "")

  let addKey = key =>
    switch Dict.get(seen, key) {
    | Some(_) => ()
    | None => {
        Dict.set(seen, key, true)
        keys->Array.push(key)
      }
    }

  rows->Array.forEach(row => Dict.toArray(row)->Array.forEach(((key, _)) => addKey(key)))
  keys
}

let buildRow = (keys: array<string>, row: rowObject): array<string> =>
  keys->Array.map(key => Dict.get(row, key)->Option.getOr(""))

let normalizeObjects = (rows: array<rowObject>): array<array<string>> => {
  if rows->Array.length == 0 {
    []
  } else {
    let keys = extractKeysOrdered(rows)
    let header = keys->Array.map(key => key)
    let body = rows->Array.map(row => buildRow(keys, row))
    [header, ...body]
  }
}

let normalizeRichObjects = (rows: array<richRowObject>): array<array<string>> => {
  if rows->Array.length == 0 {
    []
  } else {
    let keys = extractKeysOrdered(rows)
    let header = keys->Array.map(key => key)
    let body = rows->Array.map(row =>
      keys->Array.map(key =>
        switch Dict.get(row, key) {
        | Some(v) => stringifyCell(v)
        | None => ""
        }
      )
    )
    [header, ...body]
  }
}
