/**
 * Theme module for ASCIIGrid.
 *
 * Defines the character set used to draw table borders.
 * Each theme specifies 11 characters for box-drawing:
 * corners, edges, intersections, and the vertical wall.
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

/**
 * MySQL-style ASCII theme.
 * Uses +, -, and | characters.
 */
let mysql: t = {
  upperLeft: "+",
  upperRight: "+",
  lowerLeft: "+",
  lowerRight: "+",
  intersection: "+",
  line: "-",
  wall: "|",
  intersectionTop: "+",
  intersectionBottom: "+",
  intersectionLeft: "+",
  intersectionRight: "+",
}

/**
 * Unicode box-drawing theme.
 * Uses double-line characters for a refined look.
 */
let unicode: t = {
  upperLeft: "╔",
  upperRight: "╗",
  lowerLeft: "╚",
  lowerRight: "╝",
  intersection: "╬",
  line: "═",
  wall: "║",
  intersectionTop: "╦",
  intersectionBottom: "╩",
  intersectionLeft: "╠",
  intersectionRight: "╣",
}

/**
 * Oracle-style ASCII theme.
 * Uses - and | characters (no + corners).
 */
let oracle: t = {
  upperLeft: "-",
  upperRight: "-",
  lowerLeft: "-",
  lowerRight: "-",
  intersection: "-",
  line: "-",
  wall: "|",
  intersectionTop: "-",
  intersectionBottom: "-",
  intersectionLeft: "-",
  intersectionRight: "-",
}