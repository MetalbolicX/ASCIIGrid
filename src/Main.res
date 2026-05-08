/**
 * ASCIIGrid CLI entry point.
 *
 * @module Main
 */
let main = () => {
  let data: AsciiGrid.data = [
    ["Name", "Age", "City"],
    ["Alice", "30", "New York"],
    ["Bob", "25", "San Francisco"],
    ["Charlie", "35", "Chicago"],
  ]

  let options: AsciiGridOptions.t = {
    ...AsciiGridOptions.defaults,
    title: Some("Users"),
    header: true,
    align: true,
  }

  switch AsciiGrid.render(data, options) {
  | Ok(table) => Console.log(table)
  | Error(msg) => Console.error("Error: " ++ msg)
  }
}

main()
