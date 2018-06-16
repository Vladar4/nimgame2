# nimgame2/utils.nim
# Copyright (c) 2016-2018 Vladimir Arabadzhi (Vladar)
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
  math, random,
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
  return
    if angle != 0:
      (rotate(point, angle) + offset)
    else:
      (offset + point)


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


proc loadSurface*(src: ptr RWops, freeSrc: bool = true): Surface =
  ##  Load ``src`` ``RWops`` to the ``sdl.Surface``.
  ##
  ##  ``Return`` the surface on success, or `nil` otherwise.
  ##
  result = img.loadRW(src, freeSrc)
  if result == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load image RW: %s",
                    img.getError())
    return nil


proc textureFormats*(renderer: Renderer):
    tuple[num: uint32, formats: array[16, uint32]] =
  ##  ``Return`` number and array of available texture formats
  ##  from the ``renderer``.
  ##
  var info: RendererInfo
  if renderer.getRendererInfo(addr(info)) == 0:
    return (info.num_texture_formats, info.textureFormats)
  else:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get renderer texture format: %s",
                    sdl.getError())
    return


proc textureFormat*(renderer: Renderer, n: uint32 = 0): uint32 =
  ##  ``Return`` ``n``'th texture format from the ``renderer``.
  ##
  let (num, formats) = renderer.textureFormats()
  if n < num:
    return formats[n]
  else:
    sdl.logCritical(sdl.LogCategoryError,
                    "No such texture format (%d) in current renderer.", n)
    return


#=========#
# Parsing #
#=========#

import parsecsv, streams


proc readAll*(src: ptr RWops): string =
  const BufferSize = 1000
  result = newString(BufferSize)
  var r = 0
  while true:
    let readBytes = rwRead(src, addr(result[r]), sizeof(uint8), BufferSize)
    if readBytes < BufferSize:
      setLen(result, r+readBytes)
      break
    inc r, BufferSize
    setLen(result, r+BufferSize)


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


proc loadCSV*[T](src: ptr RWops,
                 file: string,
                 parse: proc(input: string): T,
                 separator = ',',
                 quote = '\"',
                 escape = '\0',
                 skipInitialSpace = true,
                 freeSrc = true): seq[seq[T]] =
  ##  Load data from ``src`` ``RWops``.
  ##
  ##  ``file`` is only used for nice error messages.
  ##
  ##  ``Return`` a two-dimensional sequence of values from the ``file``,
  ##  or empty sequence (`@[]`) otherwise.
  ##
  result = @[]
  var
    parser: CsvParser
    stream = newStringStream(src.readAll())
  parser.open(stream, file, separator, quote, escape, skipInitialSpace)
  while parser.readRow():
    result.add(@[])
    for item in parser.row:
      result[^1].add(parse(item))
  parser.close()
  stream.close()
  if freeSrc:
    freeRW(src)


import
  strutils, indexedimage


proc loadPalette(palette: var indexedimage.Palette,
                 parser: var CsvParser) =
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
  var parser: CsvParser
  parser.open(file, separator, quote, escape, skipInitialSpace)
  loadPalette(palette, parser)
  parser.close()


proc loadPalette*(palette: var indexedimage.Palette,
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


template atlasValues(parser: CsvParser): untyped =
  var val: tuple[name: string, rect: Rect]
  while parser.readRow():
    if not(parser.row.len == 5):
      continue
    val.name = parser.row[0]
    val.rect.x = parser.row[1].parseInt
    val.rect.y = parser.row[2].parseInt
    val.rect.w = parser.row[3].parseInt
    val.rect.h = parser.row[4].parseInt
    yield val


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
  var parser: CsvParser
  parser.open(file, separator, quote, escape, skipInitialSpace)
  atlasValues(parser)
  parser.close()


iterator atlasValues*(src: ptr RWops,
                      file: string,
                      separator = ',',
                      quote = '\"',
                      escape = '\0',
                      skipInitialSpace = true,
                      freeSrc = true):
    tuple[name: string, rect: Rect] =
  var
    parser: CsvParser
    stream = newStringStream(src.readAll())
  parser.open(stream, file, separator, quote, escape, skipInitialSpace)
  atlasValues(parser)
  parser.close()
  stream.close()
  if freeSrc:
    freeRW(src)


#========#
# Random #
#========#

proc random*[T](max: T, exclude: seq[T]): T {.deprecated.} =
  ##  ``Return`` a random number in the range `0`..<``max``,
  ##  except values in the ``exclude``.
  ##
  ##  ``Deprecated:`` Use ``rand`` instead.
  ##
  result = random(max)
  while exclude.contains(result):
    result = random(max)


template random*[T](max: T, exclude: openArray[T]): T {.deprecated.} =
  random(max, @exclude)


proc rand*[T](max: T, exclude: seq[T]): T =
  ##  ``Return`` a random number in the range `0`..``max``,
  ##  except values in the ``exclude``.
  ##
  result = rand(max)
  while exclude.contains(result):
    result = rand(max)


proc rand*[T](max: T, exclude: openArray[T]): T {.inline.} =
  rand(max, @exclude)


proc random*[T](x, exclude: seq[T]): T {.deprecated.} =
  ##  ``Return`` a random number in the sequence ``x``,
  ##  except values in the ``exclude``.
  ##
  ##  ``Deprecated:`` use ``rand`` instaead.
  ##
  result = random(x)
  while exclude.contains(result):
    result = random(x)


template random*[T](x, exclude: openArray[T]): T {.deprecated.} =
  random(@x, @exclude)


proc rand*[T](x, exclude: seq[T]): T =
  ##  ``Return`` a random number in the sequence ``x``,
  ##  except values in the ``exclude``.
  ##
  result = rand(x)
  while exclude.contains(result):
    result = rand(x)


proc rand*[T](x, exclude: openArray[T]): T {.inline.} =
  rand(@x, @exclude)


proc random*[T](x: Slice[T], exclude: seq[T]): T {.deprecated.} =
  ##  ``Return`` a random number in the range ``min``..<``max``,
  ##  except values in the ``exclude``.
  ##
  ##  ``Deprecated:`` use ``rand`` instead.
  ##
  result = random(x)
  while exclude.contains(result):
    result = random(x)


template random*[T](x: Slice[T], exclude: openArray[T]): T {.deprecated.} =
  random(x, @exclude)


proc rand*[T](x: Slice[T], exclude: seq[T]): T =
  ##  ``Return`` a random number in the range ``min``..``max``,
  ##  except values in the ``exclude``.
  ##
  result = rand(x)
  while exclude.contains(result):
    result = rand(x)


proc rand*[T](x: Slice[T], exclude: openArray[T]): T {.inline.} =
  rand(x, @exclude)


proc random*[T](x: set[T]): T {.deprecated.} =
  ##  ``Return`` a random member of set ``x``.
  ##
  ##  ``Deprecated:`` use ``rand`` instead.
  ##
  var r: seq[T] = @[]
  for i in x:
    r.add(i)
  return random(r)


proc rand*[T](x: set[T]): T =
  ##  ``Return`` a random member of set ``x``.
  ##
  var r: seq[T] = @[]
  for i in x:
    r.add(i)
  return rand(r)


proc randomBool*(chance: float = 0.5): bool {.deprecated.} =
  ##  ``Return`` `true` or `false`,
  ##  based on the ``chance`` value (from `0.0` to `1.0`).
  ##
  return random(1.0) < chance.clamp(0.0, 1.0)


proc randBool*(chance: float = 0.5): bool {.inline.} = randomBool(chance)


proc randomSign*(chance: float = 0.5): int =
  ##  ``Return`` `1` or `-1`,
  ##  based on the ``chance`` value (from `0.0` to `1.0`).
  ##
  return if randomBool(chance): 1 else: -1


proc randSign*(chance: float = 0.5): int {.inline.} = randomSign(chance)


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

  total = rand(T(0)..total)
  for i in 0..weights.high:
    if total < weights[i]:
      result = i
      break
    total -= weights[i]


proc randWeighted*[T](weights: openArray[T]): int {.inline.} =
  randomWeighted(weights)


#======#
# Time #
#======#

template timeDiff*(first, second: untyped): untyped = ##  \
  ##  ``first``, ``second`` two results of ``sdl.getPerformanceCounter()``.
  ##
  ##  ``Return`` time difference between two time stamps (in ms).
  ##
  int(((second - first) * 1000) div sdl.getPerformanceFrequency())


template msToSec*(ms: int): float = (ms / 1000)


template secToMs*(sec: float): int = int(sec * 1000)


type
  Counter* = ref object
    counter, current, interval: int
    time: uint64


proc newCounter*(interval: int = 1000): Counter =
  new result
  result.counter = 0
  result.current = 0
  result.interval = interval
  result.time = sdl.getPerformanceCounter()


proc update*(counter: Counter) =
  inc(counter.counter)
  let time = sdl.getPerformanceCounter()
  if timeDiff(counter.time, time) > counter.interval:
    counter.current = counter.counter
    counter.counter = 0
    counter.time = time


proc value*(counter: Counter): int {.inline.} =
  counter.current

#===========#
# Transform #
#===========#


proc point*(self: Transform, point: Coord): Coord=
  return self.pos+rotate(point, self.angle) * self.scale

proc inverse_point*(self: Transform, point: Coord): Coord=
  var
    relpoint = self.pos-point
  return self.pos-rotate(relpoint, self.pos, -self.angle)

proc translated*(self: Transform, delta: Coord):Transform=
  result = self.copy()
  result.pos += result.point(delta)

proc rotated*(self:Transform, angle: float):Transform=
  result = self.copy()
  result.angle += angle

proc scaled*(self:Transform, scale: float):Transform=
  result = self.copy()
  result.scale *= scale