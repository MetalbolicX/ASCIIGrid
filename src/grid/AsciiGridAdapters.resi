type rowObject = dict<string>

type cellValue =
  | CellString(string)
  | CellInt(int)
  | CellFloat(float)
  | CellBool(bool)
  | CellNull

type richRowObject = dict<cellValue>

let stringifyCell: cellValue => string

let normalizeMatrix: array<array<string>> => array<array<string>>
let normalizeRichMatrix: array<array<cellValue>> => array<array<string>>

let normalizeObjects: array<rowObject> => array<array<string>>
let normalizeRichObjects: array<richRowObject> => array<array<string>>
