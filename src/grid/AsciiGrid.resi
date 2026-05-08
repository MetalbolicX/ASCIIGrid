type data = array<array<string>>

let render: (data, AsciiGridOptions.t) => result<string, string>
let renderWithObjects: (
  array<AsciiGridAdapters.rowObject>,
  AsciiGridOptions.t,
  ~columnWidths: array<int>=?,
) => result<string, string>
let renderRich: (
  array<array<AsciiGridAdapters.cellValue>>,
  AsciiGridOptions.t,
) => result<string, string>
let renderWithRichObjects: (
  array<AsciiGridAdapters.richRowObject>,
  AsciiGridOptions.t,
  ~columnWidths: array<int>=?,
) => result<string, string>
