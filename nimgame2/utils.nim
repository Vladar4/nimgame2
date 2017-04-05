# nimgame2/utils.nim
# Copyright (c) 2016-2017 Vladar
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
# Vladar vladar4@gmail.com


import
  math, parsecsv, random,
  sdl2/sdl,
  texturegraphic, types


#==========#
# Geometry #
#==========#

template rad*(a: Angle): Angle =
  ##  Convert degrees to radians.
  ##
  (a * Pi / 180)


template deg*(a: Angle): Angle =
  ##  Convert radians to degrees.
  ##
  (a * 180 / Pi)


proc distance*(a, b: Coord): float {.inline.} =
  ##  ``Return`` distance between two coordinates.
  ##
  return sqrt( pow(b.x - a.x, 2) + pow(b.y - a.y, 2) )


proc distanceToLine*(a, d1, d2: Coord): float =
  ##  ``Return`` distance between point ``a`` and line ``d1``-``d2``.
  ##
  let d = d2 - d1
  return abs( d.y * a.x - d.x * a.y + d2.x * d1.y - d2.y * d1.x ) /
         sqrt( pow(d.y, 2) + pow(d.x, 2) )


proc direction*(a, b: Coord): Angle =
  ##  ``Return`` angle direction from coordinate ``a`` to ``b`` (in degrees).
  ##
  let
    dx = b.x - a.x
    dy = a.y - b.y
  return -(arctan2(dy, dx) / Pi) * 180 + 90


proc rotate*(a: Coord, angle: Angle): Coord =
  ##  Rotate point ``a`` by the given ``angle`` (in degrees).
  ##
  if angle == 0:
    return a
  let
    rot = rad(angle)
    c = cos(rot)
    s = sin(rot)
  result.x = a.x * c - a.y * s
  result.y = a.x * s + a.y * c


proc rotate*(point, offset: Coord, angle: Angle): Coord =
  ##  Rotate ``point`` by the given ``angle`` and with given ``offset``.
  ##
  ##  ``offset``  Offset coordinate (parent position)
  ##  ``point``   Point to rotate
  ##  ``angle``   Angle of rotation (in degrees)
  ##
  result = offset + point
  if angle != 0:
    result = rotate(point, angle) + offset


#==========#
# Graphics #
#==========#

import sdl2/sdl_image as img


proc loadSurface*(file: string): Surface =
  ##  Load an image ``file`` to the ``sdl.Surface``.
  ##
  ##  ``Return`` the surface on success, or `nil` otherwise.
  ##
  result = img.load(file)
  if result == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load image %s: %s",
                    file, img.getError())
    return nil


#=========#
# Parsing #
#=========#

proc loadCSV*[T](file: string,
                 parse: proc(input: string): T,
                 separator = ',',
                 quote = '\"',
                 escape = '\0',
                 skipInitialSpace = true): seq[seq[T]] =
  ##  Load data from a CSV ``file``.
  ##
  ##  ``Return`` a two-dimensional sequence of values from the ``file``,
  ##  or empty sequence (`@[]`) otherwise.
  ##
  result = @[]
  var parser: CsvParser
  parser.open(file, separator, quote, escape, skipInitialSpace)
  while parser.readRow():
    result.add(@[])
    for item in parser.row:
      result[^1].add(parse(item))
  parser.close()


import
  strutils, indexedimage


proc loadPalette*(palette: var indexedimage.Palette,
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
  var
    ncolors = 0
    colors: seq[Color] = @[]
    parser: CsvParser
    r, g, b, a: int
  parser.open(file, separator, quote, escape, skipInitialSpace)
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


iterator atlasValues*(file: string,
                      separator = ',',
                      quote = '\"',
                      escape = '\0',
                      skipInitialSpace = true):
    tuple[name: string, rect: Rect] =
  ##  Load and iterate over atlas mapping file.
  ##
  ##  Mapping should be in a format of:
  ##
  ##  ..code-block
  ##    name, x, y, w, h
  ##    ...
  ##
  var
    parser: CsvParser
    val: tuple[name: string, rect: Rect]
  parser.open(file, separator, quote, escape, skipInitialSpace)
  while parser.readRow():
    if not(parser.row.len == 5):
      continue
    val.name = parser.row[0]
    val.rect.x = parser.row[1].parseInt
    val.rect.y = parser.row[2].parseInt
    val.rect.w = parser.row[3].parseInt
    val.rect.h = parser.row[4].parseInt
    yield val


#========#
# Random #
#========#

proc random*[T](max: T, exclude: seq[T]): T =
  ##  ``Return`` a random number in the range ``min``..<``max``,
  ##  except values in the ``exclude``.
  ##
  result = random(max)
  while exclude.contains(result):
    result = random(max)


template random*[T](max: T, exclude: openArray[T]): T =
  random(max, @exclude)


proc random*[T](x, exclude: seq[T]): T =
  ##  ``Return`` a random number in the sequence ``x``,
  ##  except values in the ``exclude``.
  result = random(x)
  while exclude.contains(result):
    result = random(x)


template random*[T](x, exclude: openArray[T]): T =
  random(@x, @exclude)


proc random*[T](x: Slice[T], exclude: seq[T]): T =
  ##  ``Return`` a random number in the range ``min``..<``max``,
  ##  except values in the ``exclude``.
  ##
  result = random(x)
  while exclude.contains(result):
    result = random(x)


template random*[T](x: Slice[T], exclude: openArray[T]): T =
  random(x, @exclude)


proc random*[T](x: set[T]): T =
  ##  ``Return`` a random member of set ``x``.
  ##
  var r: seq[T] = @[]
  for i in x:
    r.add(i)
  return random(r)


proc randomBool*(chance: float = 0.5): bool =
  ##  ``Return`` `true` or `false`,
  ##  based on the ``chance`` value (from `0.0` to `1.0`).
  ##
  return random(1.0) < chance.clamp(0.0, 1.0)


proc randomSign*(chance: float = 0.5): int =
  ##  ``Return`` `1` or `-1`,
  ##  based on the ``chance`` value (from `0.0` to `1.0`).
  ##
  return if randomBool(chance): 1 else: -1


proc randomWeighted*[T](weights: openArray[T]): int =
  ##  ``Return`` a random integer, based on the ``weights`` array.
  ##
  ##  E.g., call of randomWeighted([2, 3, 5])
  ##  will have a 20% chance of returning `0`, 30% chance of returning `1`,
  ##  and 50% chance of returning `2`.
  ##
  var total: T = 0
  for i in weights:
    total += i

  total = random(T(0)..total)
  for i in 0..weights.high:
    if total < weights[i]:
      result = i
      break
    total -= weights[i]

