# nimgame2/font.nim
# Copyright (c) 2016-2019 Vladimir Arabadzhi (Vladar)
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
  sdl2/sdl,
  settings, types, utils


const
  DefaultFontColor*: Color = 0xFFFFFFFF'u32


type
  Font* = ref object of RootObj


method getError(font: Font): string {.base.} =
  $sdl.getError()


method charH*(font: Font): int {.base.} = discard


method lineDim*(font: Font, text: string): Dim {.base.} = discard


method render*(font: Font,
               line: string,
               color: Color = DefaultFontColor): Surface {.base.} = discard


proc renderLineFont*(font: Font,
                     line: string,
                     color: Color = DefaultFontColor): Surface =
  ##  Render a text ``line`` in ``font`` with given ``color``.
  ##
  ##  The result must be freed with ``freeSurface()`` afterwards.
  ##
  let
    line = if line.len < 1: " " else: line
  result = font.render(line, color)
  if result == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't render text line: %s",
                    font.getError())
    return nil


method renderLine*(font: Font,
                   line: string,
                   color: Color = DefaultFontColor): Surface {.base.} =
  ##  Base ``renderLine()`` font method.
  ##
  ##  The result must be freed with ``freeSurface()`` afterwards.
  ##
  renderLineFont(font, line, color)


proc renderTextFont*(font: Font,
                     text: openarray[string],
                     align = TextAlign.left,
                     color: Color = DefaultfontColor): Surface =
  ##  Render a multi-line ``text`` in ``font``
  ##  with given ``align`` and ``color``.
  ##
  ##  The result must be freed with ``freeSurface()`` afterwards.
  ##
  var text = @text

  # check for empty lines
  if text.len < 1: text.add(" ")
  else:
    for i in 0..text.high:
      if text[i].len < 1:
        text[i] = " "

  # find the longest line of text
  var maxw = 0

  for line in text:
    let w = font.lineDim(line).w
    if maxw < w:
      maxw = w
  let
    maxw2 = maxw div 2
    height = font.charH

  # create surface
  let
    format = renderer.textureFormat(0)
    dim: Dim = (maxw, height * text.len)

  result = createRGBSurfaceWithFormat(
      0, dim.w, dim.h, format.bitsPerPixel.cint, format)

  if result == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create font text surface: %s",
                    sdl.getError())
    return nil

  # blit
  var
    dstRect = Rect(x: 0, y: 0, w: 0, h: height)

  for i in 0..text.high:
    let ln = font.render(text[i], color)
    dstRect.w = ln.w
    dstRect.x = case align:
                of TextAlign.left:    0
                of TextAlign.center:  maxw2 - dstRect.w div 2
                of TextAlign.right:   maxw - dstRect.w
    dstRect.y = i * height
    if not(ln.blitSurface(nil, result, addr(dstRect)) == 0):
      sdl.logCritical(sdl.LogCategoryError,
                      "Can't render text: %s",
                      sdl.getError())
      result.freeSurface()
      return nil


method renderText*(font: Font,
                   text: openarray[string],
                   align = TextAlign.left,
                   color: Color = DefaultfontColor): Surface {.base.} =
  ##  Base ``renderText()`` font method.
  ##
  ##  The result must be freed with ``freeSurface()`` afterwards.
  ##
  renderTextFont(font, text, align, color)

