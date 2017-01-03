# nimgame2/truetypefont.nim
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
  sdl2/sdl_ttf as ttf,
  font, settings, types


type
  TrueTypeFont* = ref object of font.Font
    fFont: ttf.Font


proc free*(font: TrueTypeFont) =
  if not (font.fFont == nil):
    font.fFont.closeFont()
    font.fFont = nil


proc init*(font: TrueTypeFont) =
  font.fFont = nil


proc newTrueTypeFont*(): TrueTypeFont =
  new result, free
  result.init()


proc load*(font: TrueTypeFont, file: string, size: int): bool =
  result = true
  font.free()
  font.fFont = ttf.openFont(file, size)
  if font.fFont == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load font %s: %s",
                    file, ttf.getError())
    return false


method lineDim*(font: TrueTypeFont, line: string): Dim {.inline.} =
  var w, h: cint
  discard font.fFont.sizeUTF8(line, addr(w), addr(h))
  return (w.int, h.int)


proc render(font: TrueTypeFont,
            line: string,
            color: Color = DefaultFontColor): Surface =
  if font.fFont == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render nil font")
    return nil
  result = font.fFont.renderUTF8_Blended(line, color)
  if result.setSurfaceAlphaMod(color.a) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set surface aplha modifier: %s",
                    sdl.getError())


method renderLine*(font: TrueTypeFont,
                   line: string,
                   color: Color = DefaultFontColor): Texture =
  let lineSurface = font.render(line, color)
  if lineSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render text line: %s",
                    ttf.getError())
    return nil
  result = renderer.createTextureFromSurface(lineSurface)
  lineSurface.freeSurface()


method renderText*(font: TrueTypeFont,
                   text: openarray[string],
                   align = TextAlign.left,
                   color: Color = DefaultFontColor): Texture =
  var text = @text
  if text.len < 1: text.add("")
  # find the longest line of text
  var
    sz: seq[tuple[w, h: int]] = @[]
    maxw = 0
  for line in text:
    sz.add(font.lineDim(line))
    if maxw < sz[^1].w:
      maxw = sz[^1].w
  let maxw2 = maxw div 2
  # create surface
  let sampleSurface = font.render(" ")
  if sampleSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create font sample surface")
    return nil
  let
    dim: Dim = (maxw, sz[0].h * text.len)
    textSurface = createRGBSurfaceWithFormat(
      0, dim.w, dim.h,
      sampleSurface.format.BitsPerPixel.cint,
      sampleSurface.format.format)
  sampleSurface.freeSurface()
  if textSurface == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create font text surface: %s",
                    sdl.getError())
    return nil

  # blit
  var
    dstRect = Rect(x: 0, y: 0, w: 0, h: 0)
  for i in 0..text.high:
    let ln = font.render(text[i], color)
    dstRect.w = sz[i].w
    dstRect.h = sz[i].h
    dstRect.x = case align:
                of left:    0
                of center:  maxw2 - dstRect.w div 2
                of right:   maxw - dstRect.w
    dstRect.y = i * sz[i].h
    discard ln.blitSurface(nil, textSurface, addr(dstRect))

  result = renderer.createTextureFromSurface(textSurface)
  textSurface.freeSurface()
  if result == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render text: %s",
                    sdl.getError())
    return nil


