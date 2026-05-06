/**
 * Theme module for ASCIIGrid.
 *
 * Defines the character set used to draw table borders.
 *
 * @module AsciiGridTheme
 */

type t = {
  upperLeft: string,
  upperRight: string,
  lowerLeft: string,
  lowerRight: string,
  intersection: string,
  line: string,
  wall: string,
  intersectionTop: string,
  intersectionBottom: string,
  intersectionLeft: string,
  intersectionRight: string,
}

let mysql: t
let unicode: t
let oracle: t
