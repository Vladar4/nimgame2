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
    fSurface: Surface   # source font surface
    fDim, fCharDim: Dim # dimensions of surface and single character
    fChars: seq[tuple[x, y: int]] # coordinates of all characters


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


proc load*(font: BitmapFont, file: string, charDim: Dim): bool =
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
    cols = font.fDim.w div font.fCharDim.w
    rows = font.fDim.h div font.fCharDim.h
  for r in 0..(rows - 1):
    for c in 0..(cols - 1):
      font.fChars.add((font.fCharDim.w * c, font.fCharDim.h * r))


proc newBitmapFont*(): BitmapFont =
  new result, free
  result.init()


proc newBitmapFont*(file: string, charDim: Dim): BitmapFont =
  result = newBitmapFont()
  discard result.load(file, charDim)


method charH*(font: BitmapFont): int {.inline.} =
  font.fCharDim.h


method lineDim*(font: BitmapFont, line: string): Dim {.inline.} =
  (font.fCharDim.w * line.len, font.fCharDim.h)


proc render(font: BitmapFont,
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


method renderLine*(font: BitmapFont,
                   line: string,
                   color: Color = DefaultFontColor): Texture =
  let
    line = if line.len < 1: " " else: line
    lineSurface = font.render(line, color)
  if lineSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render text line: %s",
                    sdl.getError())
    return nil
  result = renderer.createTextureFromSurface(lineSurface)
  lineSurface.freeSurface()


method renderText*(font: BitmapFont,
                   text: openarray[string],
                   align = TextAlign.left,
                   color: Color = DefaultFontColor): Texture =
  var text = @text
  if text.len < 1: text.add(" ")
  # find the longest line of text
  var maxw = 0
  for line in text:
    let w = font.lineDim(line).w
    if maxw < w:
      maxw = w
  let maxw2 = maxw div 2
  # create surface
  let
    dim: Dim = (maxw, font.fCharDim.h * text.len)
    textSurface = createRGBSurfaceWithFormat(
      0, dim.w, dim.h,
      font.fSurface.format.BitsPerPixel.cint,
      font.fSurface.format.format)
  if textSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create font text surface: %s",
                    sdl.getError())
    return nil

  # blit
  var
    dstRect = Rect(x: 0, y: 0, w: 0, h: font.fCharDim.h)
  for i in 0..text.high:
    let ln = font.render(text[i], color)
    dstRect.w = ln.w
    dstRect.x = case align:
                of left:    0
                of center:  maxw2 - dstRect.w div 2
                of right:   maxw - dstRect.w
    dstRect.y = i * font.fCharDim.h
    discard ln.blitSurface(nil, textSurface, addr(dstRect))

  result = renderer.createTextureFromSurface(textSurface)
  textSurface.freeSurface()
  if result == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render text: %s",
                    sdl.getError())
    return nil

