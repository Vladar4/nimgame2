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
  ../font,
  ../graphic,
  ../textgraphic,
  ../types,
  widget

type
  GuiProgressBar* = ref object of GuiWidget
    min*, max*, value*: int
    dim: Dim
    text: TextGraphic
    bgColor, fgColor: Color
    bgGraphic, fgGraphic: Graphic


proc init*(bar: GuiProgressBar,
           dim: Dim,
           bgColor, fgColor: Color,
           font: Font,
           bgGraphic, fgGraphic: Graphic) =
  ##  TODO
  GuiWidget(bar).init()
  bar.min = 0
  bar.max = 100
  bar.value = 0
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


proc newProgressBar*(dim: Dim,
                     bgColor: Color, fgColor: Color,
                     font: Font = nil,
                     bgGraphic: Graphic = nil,
                     fgGraphic: Graphic = nil): GuiProgressBar =
  ##  TODO
  result = new GuiProgressBar
  result.init(dim, bgColor, fgColor, font, bgGraphic, fgGraphic)


proc renderGuiProgressBar*(bar: GuiProgressBar) =
  ##  Default progress bar render procedure.
  ##
  ##  Call it from your progress bar render method.
  ##
  if bar.bgGraphic == nil:
    discard #TODO draw bgColor
  else:
    discard #TODO draw bgGraphic
  if bar.fgGraphic == nil:
    discard #TODO draw fgColor
  else:
    discard #TODO draw fgGraphic
  # text
  if not(bar.text == nil):
    discard #TODO draw text


method render*(bar: GuiProgressBar) =
  bar.renderGuiProgressBar()

