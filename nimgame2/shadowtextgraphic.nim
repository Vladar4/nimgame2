# nimgame2/textgraphic.nim
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
  strutils, unicode,
  sdl2/sdl,
  sdl2/sdl_ttf as ttf,
  nimgame2/font, 
  nimgame2/truetypefont, 
  nimgame2/textgraphic, 
  nimgame2/texturegraphic, 
  nimgame2/settings, 
  nimgame2/types

type
  ShadowTextGraphic* = ref object of TextGraphic
    fShadow: Color
    fOffset_x, fOffset_y: int

#=============#
# TextGraphic #
#=============#

proc free*(text: ShadowTextGraphic) =
  TextGraphic(text).free()
  text.fShadow = DefaultFontColor
  text.fOffset_x = 0
  text.fOffset_y = 0

proc init*(text: ShadowTextGraphic, font: TrueTypeFont) =
  TextGraphic(text).init(font)
  text.fShadow = DefaultFontColor
  text.fOffset_x = 0
  text.fOffset_y = 0

proc init*(text: ShadowTextGraphic, font: TrueTypeFont, lines: seq[string], align: TextAlign, color: Color,
  shadow: Color, offset_x: int, offset_y: int) =
  TextGraphic(text).init(font, lines, align, color)
  text.fShadow = shadow
  text.fOffset_x = offset_x
  text.fOffset_y = offset_y

proc newShadowTextGraphic*(font: TrueTypeFont, lines: seq[string], color: Color,
  shadow: Color, offset_x: int, offset_y: int, align: TextAlign = TextAlign.left): ShadowTextGraphic =
  new result, free
  result.init(font, lines, align, color, shadow, offset_x, offset_y)
  result.update()


proc newShadowTextGraphic*(font: TrueTypeFont = nil): ShadowTextGraphic =
  new result, free
  result.init(font)

method actualTextRender*(s_text: ShadowTextGraphic, color: Color): Surface {.base.} = 
  if s_text.font == nil:
    return
  let num = s_text.lines.len
  if num < 1:
    result = TrueTypeFont(s_text.font).render("")
  elif num < 2:
    result = TrueTypeFont(s_text.font).render(s_text.lines[0], color)
  else:
    result = TrueTypeFont(s_text.font).renderTextSurface(s_text.lines, s_text.align, color)
  
method renderShadowText*(s_text: ShadowTextGraphic): Texture {.base.} = 
  if s_text.fOffset_x != 0 or s_text.fOffset_y != 0:
    let shadow_surface = s_text.actualTextRender(s_text.fShadow)
    let width = shadow_surface.w
    let height = shadow_surface.h
    var srcRect = Rect(x: 0, y: 0, w: width, h: height)
    var dstRect = Rect(x: s_text.fOffset_x, y: s_text.fOffset_y, w: width, h: height)
 
    let surface = createRGBSurface(0, width + s_text.fOffset_x, height + s_text.fOffset_y, 32, 
        0x000000FF'u32, 0x0000FF00'u32, 0x00FF0000'u32, 0xFF000000'u32)
    discard shadow_surface.blitSurface(addr(srcRect), surface, addr(dstRect))

    let foreground = s_text.actualTextRender(s_text.color)
    discard foreground.blitSurface(addr(srcRect), surface, addr(srcRect))
    freeSurface shadow_surface
    freeSurface foreground 
    #TODO revisar si este ultimo if es relevante.

    if surface.setSurfaceAlphaMod(s_text.color.a) != 0:
      sdl.logCritical(sdl.LogCategoryError, "Can't set surface alpha modifier: %s", sdl.getError())

    result = renderer.createTextureFromSurface(surface)
    freeSurface surface
    
  else:
    let surface = s_text.actualTextRender(s_text.color)
    if surface.setSurfaceAlphaMod(s_text.color.a) != 0:
      sdl.logCritical(sdl.LogCategoryError, "Can't set surface alpha modifier: %s", sdl.getError())

    result = renderer.createTextureFromSurface(surface)
    freeSurface surface


method update*(s_text: ShadowTextGraphic) =
  if s_text.font == nil:
    return
  discard s_text.assignTexture(s_text.renderShadowText())

proc shadow*(text: ShadowTextGraphic): Color {.inline.} =
  text.fShadow

proc `shadow=`*(text: ShadowTextGraphic, val: Color) {.inline.} =
  text.fShadow = val
  text.update()

proc offset_x*(text: ShadowTextGraphic): int {.inline.} =
  text.fOffset_x

proc `offset_x=`*(text: ShadowTextGraphic, val: int) {.inline.} =
  text.offset_x = val
  text.update()

proc offset_y*(text: ShadowTextGraphic): int {.inline.} =
  text.fOffset_y

proc `offset_y=`*(text: ShadowTextGraphic, val: int) {.inline.} =
  text.offset_y = val
  text.update()

