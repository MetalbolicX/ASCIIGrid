let validateShape = (data: array<array<string>>): result<unit, string> => {
  if data->Array.length == 0 {
    Ok()
  } else {
    let colCount = data->Array.get(0)->Option.getOr([])->Array.length
    let valid = data->Array.every(row => row->Array.length == colCount)
    if valid {
      Ok()
    } else {
      Error("Uneven number of columns")
    }
  }
}

let computeColumnWidths = (data: array<array<string>>): array<int> => {
  if data->Array.length == 0 {
    []
  } else {
    let colCount = data->Array.get(0)->Option.getOr([])->Array.length
    let lengths = Belt.Array.make(colCount, 0)
    data->Array.forEach(row =>
      for i in 0 to colCount - 1 {
        let cellLen = switch row->Array.get(i) {
        | Some(value) => value->String.length
        | None => 0
        }
        let current = switch lengths[i] {
        | Some(len) => len
        | None => 0
        }
        if cellLen > current {
          lengths[i] = cellLen
        }
      }
    )
    lengths
  }
}
