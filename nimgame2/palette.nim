# nimgame2/indexedimage.nim
# Copyright (c) 2016-2021 Vladimir Arabadzhi (Vladar)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# vladar4@gmail.com
# https://github.com/Vladar4

import
  parsecsv, streams, strutils,
  sdl2/sdl,
  types, utils


type
  PalettePtr* = ptr sdl.Palette


#=========#
# Palette #
#=========#

proc free*(palette: PalettePtr) =
  if not (palette == nil):
    palette.freePalette()


proc init*(palette: var PalettePtr, ncolors: int) =
  palette.free()
  palette = allocPalette(ncolors)


proc ncolors*(palette: PalettePtr): int =
  ##  Get the number of colors in ``palette``.
  ##
  if palette == nil:
    0
  else:
    palette.ncolors


template len*(palette: PalettePtr): int =
  ncolors(palette)


template `^^`(s, i: untyped): untyped =
  (when i is BackwardsIndex: s.len - int(i) else: int(i))


proc `[]`*(palette: PalettePtr, i: int | BackwardsIndex): Color =
  ##  Get the ``i``'th color from the ``palette``.
  ##
  let i = palette ^^ i
  if (i < 0) or (i >= palette.ncolors):
    raise newException(IndexDefect,
      "Palette color index " & $i & " is out of bounds.")
  ptrMath:
    return palette.colors[i]


proc `[]=`*(palette: PalettePtr,
            i: int | BackwardsIndex, colors: openarray[Color]) =
  ##  Change ``colors`` in the ``palette`` starting with ``i``'th color.
  ##
  let i = palette ^^ i
  if (i < 0) or ((i + colors.len) > palette.ncolors):
    raise newException(IndexDefect,
      "Palette color index range " & $i & ".." & $(i + colors.len - 1) &
      " is out of bounds.")
  if palette.setPaletteColors(
      cast[ptr Color](colors[0].unsafeAddr), i, colors.len) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Error on setting palette colors: %s",
                    sdl.getError())


proc `[]=`*(palette: PalettePtr, i: int | BackwardsIndex, color: Color) =
  ##  Change ``i``'th color in the ``palette``.
  ##
  let i = palette ^^ i
  if (i < 0) or (i >= palette.ncolors):
    raise newException(IndexDefect,
      "Palette color index " & $i & " is out of bounds.")
  palette[i] = [color]


proc loadPalette(palette: var PalettePtr, parser: var CsvParser) =
  var
    ncolors = 0
    colors: seq[Color] = @[]
    r, g, b, a: int
  while parser.readRow():
    let cols = parser.row.len
    if cols in {3, 4}:
      r = parser.row[0].parseInt
      g = parser.row[1].parseInt
      b = parser.row[2].parseInt
      a = if cols == 4: parser.row[3].parseInt
          else: 255
      inc ncolors
    else:
      continue
  if ncolors > 0:
    if not (palette == nil):
      palette.free()
    palette.init(ncolors)
    palette[0] = colors


proc loadPalette*(palette: var PalettePtr,
                  file: string,
                  separator = ' ',
                  quote = '\"',
                  escape = '\0',
                  skipInitialSpace = true) =
  ##  Load palette color data from a ``file``.
  ##
  ##  ``palette`` Target palette. If ``palette`` is `nil`,
  ##  allocates a new palette, otherwise the ``palette`` will be freed.
  ##
  ##  Data file should be in a format of:
  ##
  ##  .. code-block
  ##    rrr ggg bbb aaa
  ##    ...
  ##
  ##  or
  ##
  ##  .. code-block
  ##    rrr ggg bbb
  ##
  ##  where `rrr`, `ggg`, `bbb`, and `aaa` is in `0`..`255` range.
  ##
  ##  Other types of lines are ignored.
  ##
  var parser: CsvParser
  parser.open(file, separator, quote, escape, skipInitialSpace)
  loadPalette(palette, parser)
  parser.close()


proc loadPalette*(palette: var PalettePtr,
                  src: ptr RWops,
                  file: string,
                  separator = ' ',
                  quote = '\"',
                  escape = '\0',
                  skipInitialSpace = true,
                  freeSrc = true) =
  var
    parser: CsvParser
    stream = newStringStream(src.readAll())
  parser.open(stream, file, separator, quote, escape, skipInitialSpace)
  loadPalette(palette, parser)
  parser.close()
  stream.close()
  if freeSrc:
    freeRW(src)

