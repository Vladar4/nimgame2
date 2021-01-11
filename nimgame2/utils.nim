# nimgame2/utils.nim
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
  math,
  sdl2/sdl,
  texturegraphic, settings, types


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


export pointInRect  ##  From SDL2, returns true if sdl.Point is in sdl.Rect.

proc pointInRect*(p, pos: Coord, dim: Dim): bool =
  ##  ``Return`` `true` if ``p`` is contained in rect with ``pos`` and ``dim``,
  ##  or `false` otherwise.
  ##
  ((p.x >= pos.x) and (p.x < (pos.x + dim.w.float)) and
   (p.y >= pos.y) and (p.y < (pos.y + dim.h.float)))


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


proc createSurface*(texture: Texture,
    rect = sdl.Rect(x:0, y:0, w:0, h:0)): Surface =
  ##  ``rect`` Area of a source texture to create the surface from.
  ##  Empty rect (default) uses the whole texture.
  ##
  ##  ``WARNING:`` Potentially unstable, use at your own risk.
  ##  If possible, usage of SurfaceGraphic is preferrable.
  ##
  ##  ``Return`` a surface created from a texture. Slow, so use wisely.
  var
    fmt: uint32
    w, h: cint
    srcRect, dstRect: sdl.Rect
    target: Texture
    pitch: cint
    pixels: pointer

  template reset(old: typed, success = false) =
    if not (renderer.setRenderTarget(old) == 0):
      sdl.logCritical(sdl.LogCategoryError,
                      "Can't reset a render target.")
    if not (target == nil):
      destroyTexture(target)
    if not (pixels == nil):
      dealloc(pixels)
    if not success:
      if not (result == nil):
        freeSurface(result)

  # query
  if not (queryTexture(texture, addr(fmt), nil, addr(w), addr(h)) == 0):
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't query a texture.")
    return nil
  # srcRect
  if rectEmpty(rect):
    srcRect = Rect(x:0, y:0, w:w, h:h)
  else:
    srcRect = rect
  # dstRect
  dstRect = Rect(x:0, y:0, w:srcRect.w, h:srcRect.h)
  pitch = fmt.bytesPerPixel * srcRect.w
  # create render target
  target = renderer.createTexture(
    fmt, TextureAccessTarget, dstRect.w, dstRect.h)
  let oldTarget = renderer.getRenderTarget()
  # set render target
  if not (renderer.setRenderTarget(target) == 0):
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set a render target to a texture.")
    reset(oldTarget)
    return nil
  # render
  if not (renderer.renderCopy(texture, addr(srcRect), addr(dstRect)) == 0):
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't renderCopy into a texture.")
    reset(oldTarget)
    return nil
  # alloc pixels
  pixels = alloc(pitch * dstRect.h)
  if pixels == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't allocate the pixels.")
    reset(oldTarget)
    return nil
  # read pixels
  if not (renderer.renderReadPixels(nil, fmt, pixels, pitch) == 0):
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't read pixles from a texture.")
    reset(oldTarget)
    return nil
  # create surface
  result = createRGBSurfaceWithFormatFrom(pixels,
    dstRect.w, dstRect.h, fmt.bitsPerPixel.cint, pitch, fmt)
  # reset render target
  reset(oldTarget, true)


#=========#
# Parsing #
#=========#

import parsecsv, streams, strutils


proc readAll*(src: ptr RWops): string =
  const BufferSize = 1000
  result = newString(BufferSize)
  var r = 0
  while true:
    let readBytes = int rwRead(src, addr(result[r]), csize_t sizeof(uint8), BufferSize)
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

import random
export random

#== max ==#

proc rand*[T](max: T, exclude: seq[T]): T =
  ##  ``Return`` a random number in the range `0`..``max``,
  ##  except values in the ``exclude``.
  ##
  result = random.rand(max)
  while exclude.contains(result):
    result = random.rand(max)

template rand*[T](max: T, exclude: openArray[T]): T =
  rand(max, @exclude)


#== seq ==#

proc rand*[T](x, exclude: seq[T]): T =
  ##  ``Return`` a random number in the sequence ``x``,
  ##  except values in the ``exclude``.
  ##
  result = random.sample(x)
  while exclude.contains(result):
    result = random.sample(x)

template rand*[T](x, exclude: openArray[T]): T =
  rand(@x, @exclude)


#== slice ==#

proc rand*[T](x: HSlice[T,T], exclude: seq[T]): T =
  ##  ``Return`` a random number in the range ``min``..``max``,
  ##  except values in the ``exclude``.
  ##
  result = rand(x)
  while exclude.contains(result):
    result = rand(x)

template rand*[T](x: HSlice[T,T], exclude: openArray[T]): T =
  rand(x, @exclude)


#== misc ==#

proc randBool*(chance: float = 0.5): bool {.inline.} =
  return random.rand(1.0) < chance.clamp(0.0, 1.0)


proc randSign*(chance: float = 0.5): int =
  ##  ``Return`` `1` or `-1`,
  ##  based on the ``chance`` value (from `0.0` to `1.0`).
  ##
  return if randBool(chance): 1 else: -1


proc randWeighted*[T](weights: openArray[T]): int =
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


#======#
# Time #
#======#

export # from SDL2 timers
  getTicks, getPerformanceCounter, getPerformanceFrequency, delay, ticksPassed


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

