# nimgame2/bitmapfont.nim
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
  sdl2/sdl,
  sdl2/sdl_image as img,
  font, settings, types


type
  BitmapFont* = ref object of Font
    # Private
    fSurface: Surface     ##  Source font surface
    fDim, fCharDim: Dim   ##  Dimensions of the surface and a single character
    fChars: seq[CoordInt] ##  Coordinates of all characters


#============#
# BitmapFont #
#============#

proc free*(font: BitmapFont) =
  if not (font.fSurface == nil):
    font.fSurface.freeSurface()
  font.fDim = (0, 0)
  font.fCharDim = (0, 0)
  font.fChars = @[]


proc init*(font: BitmapFont) =
  font.fSurface = nil
  font.fDim = (0, 0)
  font.fCharDim = (0, 0)
  font.fChars = @[]


proc load*(font: BitmapFont, file: string, charDim: Dim,
           offset: Dim = (0, 0), border: Dim = (0, 0)): bool =
  ##  Load ``font`` data from a ``file``.
  ##
  ##  ``charDim`` dimensions of a single font character.
  ##
  ##  ``offset``  offset from the edge of the texture.
  ##
  ##  ``border``  border around individual characters.
  ##
  ##  ``Return`` `true` on success, or `false` otherwise.
  ##
  result = true
  font.free()
  font.fSurface = img.load(file)
  if font.fSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load font %s: %s",
                    file, img.getError())
    return false

  font.fDim = (font.fSurface.w.int, font.fSurface.h.int)
  font.fCharDim = charDim
  let
    cols = (font.fDim.w - offset.w) div
           (font.fCharDim.w + 2 * border.w)
    rows = (font.fDim.h - offset.h) div
           (font.fCharDim.h + 2 * border.h)
  for r in 0..(rows - 1):
    for c in 0..(cols - 1):
      font.fChars.add((
        offset.w + font.fCharDim.w * c + border.w * (1 + c * 2),
        offset.h + font.fCharDim.h * r + border.h * (1 + r * 2)))


proc newBitmapFont*(): BitmapFont =
  new result, free
  result.init()


proc newBitmapFont*(file: string, charDim: Dim): BitmapFont =
  ##  Create and load a new bitmap font from a ``file``.
  ##
  ##  ``charDim`` dimensions of a single font character.
  ##
  result = newBitmapFont()
  discard result.load(file, charDim)


method charH*(font: BitmapFont): int {.inline.} =
  ##  ``Return`` a font character's height.
  ##
  font.fCharDim.h


method lineDim*(font: BitmapFont, line: string): Dim {.inline.} =
  ##  ``Return`` dimensions of a ``line`` of text, written in ``font``.
  ##
  (font.fCharDim.w * line.len, font.fCharDim.h)


proc renderBitmapFont*(font: BitmapFont,
                       line: string,
                       color: Color = DefaultFontColor): Surface =
  if font.fSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render nil font surface")
    return nil

  # create surface
  let
    dim = font.lineDim(line)
    lineSurface = createRGBSurfaceWithFormat(
      0, dim.w, dim.h,
      font.fSurface.format.BitsPerPixel.cint,
      font.fSurface.format.format)
  if lineSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create font line surface: %s",
                    sdl.getError())
    return nil

  # color and alpha mod
  if lineSurface.setSurfaceColorMod(color.r, color.g, color.b) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set surface color modifier: %s",
                    sdl.getError())
  if lineSurface.setSurfaceAlphaMod(color.a) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set surface alpha modifier: %s",
                    sdl.getError())

  # blit
  var
    srcRect = Rect(x: 0, y: 0, w: font.fCharDim.w, h: font.fCharDim.h)
    dstRect = Rect(x: 0, y: 0, w: font.fCharDim.w, h: font.fCharDim.h)
  for i in 0..line.high:
    var idx = line[i].ord
    if idx > font.fChars.high:
      idx = 0
    let ch = font.fChars[idx]
    srcRect.x = ch.x
    srcRect.y = ch.y
    dstRect.x = i * font.fCharDim.w
    discard font.fSurface.blitSurface(addr(srcRect), lineSurface, addr(dstRect))
  return lineSurface


method render*(font: BitmapFont,
               line: string,
               color: Color = DefaultFontColor): Surface =
  renderBitmapFont(font, line, color)

