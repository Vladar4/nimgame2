# nimgame2/gui/progressbar.nim
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
  strutils,
  ../draw,
  ../font,
  ../textgraphic,
  ../texturegraphic,
  ../types,
  widget

type
  GuiProgressBar* = ref object of GuiWidget
    min*, max*, value*: float
    precision*: range[0..32]  ## value format precision (defaults to 0)
    unit*: string             ## value format unit (defaults to '%')
    decimalSep*: char       ## value format decimal separator (defaults to '.')
    direction*: Direction
    dim*: Dim
    text: TextGraphic
    outline*: Dim            ## outline border size
    bgColor*, fgColor*: Color
    bgGraphic*, fgGraphic*: TextureGraphic
    reverseX*, reverseY*: bool


proc init*(bar: GuiProgressBar,
           dim: Dim,
           bgColor, fgColor: Color,
           font: Font,
           bgGraphic, fgGraphic: TextureGraphic) =
  ##  GuiProgressBar initialization.
  ##
  ##  ``dim`` bar's dimensions.
  ##
  ##  ``bgColor``, ``fgColor`` background (empty) and foreground (full) colors.
  ##
  ##  ``font``  info text font. Might be `nil`.
  ##
  ##  ``bgGraphic``, ``fgGraphic`` background (empty) and foreground (full)
  ##  textures that replace ``bgColor`` and ``fgColor`` if specified.
  ##
  GuiWidget(bar).init()
  bar.min = 0
  bar.max = 100
  bar.value = 0
  bar.precision = 0
  bar.unit = "%"
  bar.decimalSep = '.'
  bar.direction = Direction.leftRight
  bar.dim = dim
  bar.bgColor = bgColor
  bar.fgColor = fgColor
  if font == nil:
    bar.text = nil
  else:
    bar.text = newTextGraphic(font)
    bar.text.setText("0%")
  bar.bgGraphic = bgGraphic
  bar.fgGraphic = fgGraphic
  bar.reverseX = false
  bar.reverseY = false


proc newProgressBar*(dim: Dim,
                     bgColor: Color, fgColor: Color,
                     font: Font = nil,
                     bgGraphic: TextureGraphic = nil,
                     fgGraphic: TextureGraphic = nil): GuiProgressBar =
  ##  Create a new GuiProgressBar.
  ##
  ##  ``dim`` bar's dimensions.
  ##
  ##  ``bgColor``, ``fgColor`` background (empty) and foreground (full) colors.
  ##
  ##  ``font``  info text font. Might be `nil`.
  ##
  ##  ``bgGraphic``, ``fgGraphic`` background (empty) and foreground (full)
  ##  textures that replace ``bgColor`` and ``fgColor`` if specified.
  ##
  result = new GuiProgressBar
  result.init(dim, bgColor, fgColor, font, bgGraphic, fgGraphic)


proc renderGuiProgressBar*(bar: GuiProgressBar) =
  ##  Default progress bar render procedure.
  ##
  ##  Call it from your progress bar render method.
  ##
  # background
  if bar.bgGraphic == nil:
    discard box(
      bar.pos - Coord(bar.outline),
      bar.pos + Coord(bar.dim - (1, 1) + bar.outline),
      bar.bgColor)
  else:
    bar.bgGraphic.drawTiled(Rect(
      x: bar.pos.x.cint - bar.outline.w.cint,
      y: bar.pos.y.cint - bar.outline.h.cint,
      w: bar.dim.w.cint + bar.outline.w.cint * 2,
      h: bar.dim.h.cint + bar.outline.h.cint * 2),
      reverseX = bar.reverseX,
      reverseY = bar.reverseY)

  # foreground
  if bar.value > 0:

    let value = (bar.value - bar.min) / (bar.max - bar.min)
    var part: Coord = case bar.direction:
      of Direction.leftRight, Direction.rightLeft:
        (int(bar.dim.w.float * value), bar.dim.h)
      of Direction.bottomTop, Direction.topBottom:
        (bar.dim.w, int(bar.dim.h.float * value))

    if bar.fgGraphic == nil:
      case bar.direction:
      of Direction.leftRight, Direction.topBottom:
        discard box(
          bar.pos,
          bar.pos + part - (1.0, 1.0),
          bar.fgColor)
      of Direction.rightLeft:
        discard box(
          (bar.pos.x + bar.dim.w.float - part.x, bar.pos.y),
          bar.pos + Coord(bar.dim) - (1.0, 1.0),
          bar.fgColor)
      of Direction.bottomTop:
        discard box(
          (bar.pos.x, bar.pos.y + bar.dim.h.float - part.y),
          bar.pos + Coord(bar.dim) - (1.0, 1.0),
          bar.fgColor)
      else:
        discard

    else:
      case bar.direction:
      of Direction.leftRight, Direction.topBottom:
        bar.fgGraphic.drawTiled(Rect(
          x: bar.pos.x.cint,
          y: bar.pos.y.cint,
          w: part.x.cint,
          h: part.y.cint),
          reverseX = bar.reverseX,
          reverseY = bar.reverseY)
      of Direction.rightLeft:
        bar.fgGraphic.drawTiled(Rect(
          x: cint(bar.pos.x + bar.dim.w.float - part.x),
          y: bar.pos.y.cint,
          w: part.x.cint,
          h: part.y.cint),
          reverseX = bar.reverseX,
          reverseY = bar.reverseY)
      of Direction.bottomTop:
        bar.fgGraphic.drawTiled(Rect(
          x: bar.pos.x.cint,
          y: cint(bar.pos.y + bar.dim.h.float - part.y),
          w: part.x.cint,
          h: part.y.cint),
          reverseX = bar.reverseX,
          reverseY = bar.reverseY)

  # text
  if not(bar.text == nil):
    bar.text.setText(formatEng(
      bar.value,
      precision = bar.precision,
      decimalSep = bar.decimalSep) & bar.unit)
    let offset = bar.dim / 2.0 - Coord(bar.text.dim) / 2.0
    bar.text.draw(bar.pos + offset)


method render*(bar: GuiProgressBar) =
  bar.renderGuiProgressBar()

