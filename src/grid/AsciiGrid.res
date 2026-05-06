type data = array<array<string>>

let validateTitle = (
  title: option<string>,
  colWidths: array<int>,
  theme: AsciiGridTheme.t,
  padding: int,
): result<array<string>, string> =>
  switch title {
  | None => Ok([])
  | Some(t) => {
      let sep = AsciiGridRenderers.createSeparator(
        colWidths,
        AsciiGridRenderers.TitleTop,
        theme,
        padding,
      )
      let available = sep->String.length - 2
      if t->String.length > available {
        Error("Title is too large")
      } else {
        let lines = [
          sep,
          AsciiGridRenderers.buildTitleLine(t, available, theme),
          AsciiGridRenderers.createSeparator(
            colWidths,
            AsciiGridRenderers.TitleBottom,
            theme,
            padding,
          ),
        ]
        Ok(lines)
      }
    }
  }

let renderNormalized = (rawData: array<array<string>>, options: AsciiGridOptions.t): result<
  string,
  string,
> => {
  switch AsciiGridLayout.validateShape(rawData) {
  | Error(msg) => Error(msg)
  | Ok() => {
      let transformed = AsciiGridTransformers.applySpreadsheetMode(rawData, options)
      let colWidths = AsciiGridLayout.computeColumnWidths(transformed)
      let theme = options.AsciiGridOptions.theme
      let padding = options.AsciiGridOptions.padding

      switch validateTitle(options.AsciiGridOptions.title, colWidths, theme, padding) {
      | Error(msg) => Error(msg)
      | Ok(titleLines) => {
          let lines = Belt.Array.make(0, "")
          let addLine = line => lines->Array.push(line)

          if titleLines->Array.length == 0 {
            addLine(
              AsciiGridRenderers.createSeparator(colWidths, AsciiGridRenderers.Top, theme, padding),
            )
          } else {
            titleLines->Array.forEach(addLine)
          }

          for i in 0 to transformed->Array.length - 1 {
            let row = transformed->Array.get(i)->Option.getOr([])
            addLine(
              AsciiGridRenderers.renderRow(
                row,
                colWidths,
                theme,
                padding,
                options.AsciiGridOptions.align,
              ),
            )

            let shouldAddMiddle = if options.AsciiGridOptions.spreadsheet {
              i == 0 || (options.AsciiGridOptions.header && i == 1)
            } else {
              options.AsciiGridOptions.header && i == 0
            }
            if shouldAddMiddle {
              addLine(
                AsciiGridRenderers.createSeparator(
                  colWidths,
                  AsciiGridRenderers.Middle,
                  theme,
                  padding,
                ),
              )
            }
          }

          addLine(
            AsciiGridRenderers.createSeparator(
              colWidths,
              AsciiGridRenderers.Bottom,
              theme,
              padding,
            ),
          )

          let table = lines->Array.reduce("", (acc, line) =>
            if acc == "" {
              line
            } else {
              acc ++ "\n" ++ line
            }
          )
          Ok(table)
        }
      }
    }
  }
}

let render = (data: data, options: AsciiGridOptions.t): result<string, string> =>
  renderNormalized(data, options)

let renderWithObjects = (
  rows: array<AsciiGridAdapters.rowObject>,
  options: AsciiGridOptions.t,
): result<string, string> => {
  let normalized = AsciiGridAdapters.normalizeObjects(rows)
  renderNormalized(normalized, options)
}
