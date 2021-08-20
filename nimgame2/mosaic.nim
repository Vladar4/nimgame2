# nimgame2/mosaic.nim
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
  sdl2_nim/sdl,
  sdl2_nim/sdl_image as img,
  settings, types


type
  MosaicPattern* = seq[seq[int]]

  Mosaic* = ref object of RootObj
    # Private
    fSurface: Surface   ##  Source surface
    fDim: Dim           ##  Dimensions of the surface
    # Public
    tileDim*, offset*: Dim ## \
      ##  Dimensions of a single mosaic tile, and offset from the edge.


#========#
# Mosaic #
#========#

proc free*(mosaic: Mosaic) =
  if not (mosaic.fSurface == nil):
    mosaic.fSurface.freeSurface()
  mosaic.fDim = (0, 0)
  mosaic.tileDim = (0, 0)
  mosaic.offset = (0, 0)


proc init*(mosaic: Mosaic) =
  mosaic.free()
  mosaic.fSurface = nil
  mosaic.fDim = (0, 0)
  mosaic.tileDim = (0, 0)
  mosaic.offset = (0, 0)


template afterLoad(mosaic: Mosaic, tileDIm: Dim, offset: Dim = (0, 0)) =
  mosaic.fDim = (mosaic.fSurface.w.int, mosaic.fSurface.h.int)
  mosaic.tileDim = tileDim
  mosaic.offset = offset


proc load*(mosaic: Mosaic, file: string,
           tileDim: Dim, offset: Dim = (0, 0)): bool =
  ##  Load ``mosaic`` graphic source from a ``file``.
  ##
  ##  ``tileDim`` dimensions of a single mosaic tile.
  ##
  ##  ``offset`` offset from the edge.
  ##
  ##  ``Return`` `true` on success, or `false` otherwise.
  ##
  result = true
  mosaic.free()
  # load image
  mosaic.fSurface = img.load(file)
  if mosaic.fSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load mosaic %s: %s",
                    file, img.getError())
    return false
  # after-load
  afterLoad(mosaic, tileDim, offset)


proc load*(mosaic: Mosaic, src: ptr RWops,
           tileDim: Dim, offset: Dim = (0, 0),
           freeSrc: bool = true): bool =
  result = true
  mosaic.free()
  # load image
  mosaic.fSurface = img.loadRW(src, freeSrc)
  if mosaic.fSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load mosaic RW: %s",
                    img.getError())
    return false
  # after-load
  afterLoad(mosaic, tileDim, offset)


proc newMosaic*(): Mosaic =
  new result, free
  result.init()


proc newMosaic*(file: string,
                tileDim: Dim, offset: Dim = (0, 0)): Mosaic =
  ##  Create a new Mosaic and load tileset from a ``file``.
  ##
  ##  ``tileDim`` the size of a single tile.
  ##
  ##  ``offset``  offset from the edge of the tileset.
  ##
  result = newMosaic()
  discard result.load(file, tileDim, offset)


proc newMosaic*(src: ptr RWops,
                tileDim: Dim, offset: Dim = (0, 0),
                freeSrc: bool = true): Mosaic =
  result = newMosaic()
  discard result.load(src, tileDim, offset, freeSrc)


proc dim*(mosaic: Mosaic): Dim {.inline.} =
  mosaic.fDim


proc renderSurface*(mosaic: Mosaic, pattern: MosaicPattern): Surface =
  ##  ``Return`` a new ``Surface`` created with ``mosaic`` tiles
  ##  by a given ``pattern``.
  ##
  if mosaic.fSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render nil mosaic surface")
    return nil
  # calculate tiles positioning
  let tileNum: Dim = (mosaic.fDim - mosaic.offset) / mosaic.tileDim
  # get pattern dimensions (in tiles)
  var patternDim: Dim = (0, 0)
  for line in pattern:
    inc patternDim.h
    if line.len > patternDim.w:
      patternDim.w = line.len

  if (patternDim.w < 1) or (patternDim.h < 1):
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create a mosaic surface of %dx%d size.",
                    patternDim.w, patternDim.h)
    return nil
  # create surface
  let
    dim = mosaic.tileDim * patternDim
    surface = createRGBSurfaceWithFormat(
      0, dim.w, dim.h,
      mosaic.fSurface.format.BitsPerPixel.cint,
      mosaic.fSurface.format.format)
  if surface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create mosaic surface: %s",
                    sdl.getError())
    return nil

  # blit
  var
    srcRect = Rect(x: 0, y: 0, w: mosaic.tileDim.w, h: mosaic.tileDim.h)
    dstRect = Rect(x: 0, y: 0, w: mosaic.tileDim.w, h: mosaic.tileDim.h)
  for y in 0..pattern.high:
    for x in 0..pattern[y].high:
      let
        idx = pattern[y][x]
        num: Dim = (w: idx mod tileNum.w,
                    h: idx div tileNum.w)
        pos: Dim = mosaic.offset + mosaic.tileDim * num
      srcRect.x = pos.w
      srcRect.y = pos.h
      dstRect.x = x * mosaic.tileDim.w
      dstRect.y = y * mosaic.tileDim.h
      discard mosaic.fSurface.blitSurface(addr(srcRect), surface, addr(dstRect))
  return surface


proc render*(mosaic: Mosaic, pattern: MosaicPattern): Texture =
  ##  ``Return`` a new ``Texture`` created with ``mosaic`` tiles
  ##  by a given ``pattern``.
  ##
  let surface = mosaic.renderSurface(pattern)
  if surface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render mosaic pattern: %s",
                    sdl.getError())
    return nil
  result = renderer.createTextureFromSurface(surface)
  surface.freeSurface()


#==========#
# Patterns #
#==========#

type
  RepeatPattern* = seq[tuple[rows, cols: int, data: seq[int]]]  ##  \
    ##  RepeatPattern meaning:
    ##
    ##  .. code-block:: nim
    ##    RepeatPattern = seq[tuple[rows, cols: int, data: seq[int]]]
    ##
    ##  * ``rows`` repeat this row ``rows`` times
    ##
    ##  * ``cols`` repeat this ``data`` sequence ``cols`` times,
    ##  gradually increasing the index.
    ##
    ##  * ``data`` for each ``item`` repeat increasing index ``item`` times.
    ##
    ##  ``Example:``
    ##
    ##  .. code-block:: nim
    ##    patternRepeat(@[
    ##      (1, 2, @[1, 2, 1]),
    ##      (2, 2, @[1, 2, 1]),
    ##      (1, 2, @[1, 2, 1]),
    ##    ])
    ##
    ##  will return:
    ##
    ##  .. code-block:: nim
    ##    @[
    ##      @[0, 1, 1, 2, 3, 4, 4, 5],
    ##      @[6, 7, 7, 8, 9, 10, 10, 11],
    ##      @[6, 7, 7, 8, 9, 10, 10, 11],
    ##      @[12, 13, 13, 14, 15, 16, 16, 17]
    ##    ]
    ##


proc patternRepeat*(repeat: RepeatPattern): MosaicPattern =
  ##  Generate a repeating pattern. Useful for generating GUI elements
  ##  of different sizes with ``Mosaic``.
  ##
  ##  ``See also:`` ``RepeatPattern`` type.
  ##
  result = @[]
  var idx = 0
  for line in repeat:
    var rowData: seq[int] = @[]
    # repeat item times
    for col in 0..<line.cols:
      for item in line.data:
        for itemCount in 0..<item:
          rowData.add idx
        inc idx
    for rowCount in 0..<line.rows:
      result.add rowData


proc patternStretchBorder*(w, h: int, nx = 2, ny = 3): MosaicPattern =
  ##  Generate a repeating pattern by repeating border items of 3x3 matrix
  ##  (used for GUI buttons, etc.)
  ##
  ##  `w`, `h` strethed parts repeat count.
  ##
  ##  `nx`, `ny`  number of elements in the matrix.
  ##
  var pat: RepeatPattern = @[]
  for i in 0..<ny:
    pat.add((1, nx, @[1, w, 1]))
    pat.add((h, nx, @[1, w, 1]))
    pat.add((1, nx, @[1, w, 1]))
  return patternRepeat(pat)

