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


#==============#
# TrueTypeFont #
#==============#

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
  ##  Load ``font`` data from a ``file``.
  ##
  ##  ``size`` required font size.
  ##
  result = true
  font.free()
  font.fFont = ttf.openFont(file, size)
  if font.fFont == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't load font %s: %s",
                    file, ttf.getError())
    return false


method getError*(font: TrueTypeFont): string =
  $ttf.getError()


method charH*(font: TrueTypeFont): int =
  ##  ``Return`` a font character's height.
  ##
  if font.fFont == nil:
    return 0
  return font.fFont.fontHeight()


method lineDim*(font: TrueTypeFont, line: string): Dim =
  ##  ``Return`` dimensions of a ``line`` of text, written in ``font``.
  ##
  if font.fFont == nil:
    return (0, 0)
  var w, h: cint
  discard font.fFont.sizeUTF8(line, addr(w), addr(h))
  return (w.int, h.int)


method render(font: TrueTypeFont,
              line: string,
              color: Color = DefaultFontColor): Surface =
  if font.fFont == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render nil font")
    return nil
  if line.len < 1:
    return nil
  result = font.fFont.renderUTF8_Blended(line, color)
  if result.setSurfaceAlphaMod(color.a) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't set surface alpha modifier: %s",
                    sdl.getError())

