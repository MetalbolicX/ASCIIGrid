type rowObject = dict<string>

let normalizeMatrix = (rows: array<array<string>>): array<array<string>> => rows

let extractKeysOrdered = (rows: array<rowObject>): array<string> => {
  let seen = Dict.make()
  let keys = Belt.Array.make(0, "")

  let addKey = key =>
    switch Dict.get(seen, key) {
    | Some(_) => ()
    | None => {
        Dict.set(seen, key, true)
        keys->Belt.Array.push(key)
      }
    }

  rows->Belt.Array.forEach(row =>
    Dict.toArray(row)
    ->Belt.Array.forEach(((key, _value)) => addKey(key)))
  keys
}

let buildRow = (keys: array<string>, row: rowObject): array<string> =>
  keys->Belt.Array.map(key => Dict.get(row, key)->Belt.Option.getWithDefault(""))

let normalizeObjects = (rows: array<rowObject>): array<array<string>> => {
  if rows->Belt.Array.length == 0 {
    []
  } else {
    let keys = extractKeysOrdered(rows)
    let header = keys->Belt.Array.map(key => key)
    let body = rows->Belt.Array.map(row => buildRow(keys, row))
    [header, ...body]
  }
}
