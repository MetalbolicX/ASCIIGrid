type data = array<array<string>>

let render: (data, AsciiGridOptions.t) => result<string, string>
let renderWithObjects: (array<AsciiGridAdapters.rowObject>, AsciiGridOptions.t) => result<string, string>
