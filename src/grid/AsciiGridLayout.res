let validateShape = (data: array<array<string>>): result<unit, string> => {
  if data->Belt.Array.length == 0 {
    Ok(())
  } else {
    let colCount = data->Belt.Array.get(0)->Belt.Option.getWithDefault([])->Belt.Array.length
    let valid = data->Belt.Array.every(row => row->Belt.Array.length == colCount)
    if valid {
      Ok(())
    } else {
      Error("Uneven number of columns")
    }
  }
}

let computeColumnWidths = (data: array<array<string>>): array<int> => {
  if data->Belt.Array.length == 0 {
    []
  } else {
    let colCount = data->Belt.Array.get(0)->Belt.Option.getWithDefault([])->Belt.Array.length
    let lengths = Belt.Array.make(colCount, 0)
    data->Belt.Array.forEach(row =>
      for i in 0 to colCount - 1 {
        let cellLen = switch row->Belt.Array.get(i) {
        | Some(value) => value->String.length
        | None => 0
        }
        let current = switch Belt.Array.get(lengths, i) {
        | Some(len) => len
        | None => 0
        }
        if cellLen > current {
          lengths[i] = cellLen
        }
      })
    lengths
  }
}
