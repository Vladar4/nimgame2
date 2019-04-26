# nimgame2/gui/progressbar.nim
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
  strutils,
  ../draw,
  ../entity,
  ../font,
  ../textgraphic,
  ../texturegraphic,
  ../types,
  ../utils,
  button,
  widget

type
  GuiBar* = ref object of GuiWidget
    # Private
    fText: TextGraphic
    # Public
    min*, max*, value*: float
    precision*: range[0..32]  ## value format precision (defaults to 0)
    unit*: string             ## value format unit (defaults to '%')
    decimalSep*: char       ## value format decimal separator (defaults to '.')
    direction*: Direction   ## value increase direction
    dim*: Dim               ## bar dimensions
    outline*: Dim           ## outline border size
    bgColor*, fgColor*: Color
    bgGraphic*, fgGraphic*: TextureGraphic
    reverseX*, reverseY*: bool  ## reverse options for bgGraphic and fgGraphic
    showBg*, showFg*: bool      ## set to false to hide background or foreground
    editable*: bool             ## set to true to be able to "drag" the value
    button*: GuiButton          ## optional button for the bar
    buttonText*: bool           ## set to `true` to replace button's image \
                                ## with text showing bar's current value


proc initGuiBar*(
    bar: GuiBar,
    dim: Dim,
    bgColor, fgColor: Color,
    font: Font,
    bgGraphic: TextureGraphic = nil, fgGraphic: TextureGraphic = nil,
    button: GuiButton = nil, buttonText: bool = false) =
  ##  GuiBar initialization.
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
  bar.initGuiWidget()
  bar.min = 0
  bar.max = 100
  bar.value = 0
  bar.precision = 0
  bar.unit = "%"
  bar.decimalSep = '.'
  bar.direction = Direction.leftRight
  bar.dim = dim
  # collider
  bar.collider = bar.newBoxCollider(bar.dim / 2, bar.dim)
  bar.bgColor = bgColor
  bar.fgColor = fgColor
  if font == nil:
    bar.fText = nil
  else:
    bar.fText = newTextGraphic(font)
    bar.fText.setText("0%")
  bar.bgGraphic = bgGraphic
  bar.fgGraphic = fgGraphic

  bar.reverseX = false
  bar.reverseY = false
  bar.showBg = true
  bar.showFg = true
  bar.editable = false

  bar.button = button
  bar.buttonText = buttonText


proc newGuiBar*(
    dim: Dim,
    bgColor: Color, fgColor: Color,
    font: Font = nil,
    bgGraphic: TextureGraphic = nil,
    fgGraphic: TextureGraphic = nil,
    button: GuiButton = nil,
    buttonText: bool = false): GuiBar =
  ##  Create a new GuiBar.
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
  result = new GuiBar
  result.initGuiBar(dim, bgColor, fgColor, font, bgGraphic, fgGraphic,
                            button, buttonText)


proc eventGuiBar*(bar: GuiBar, e: Event) =
  bar.eventGuiWidget(e)
  if bar.button != nil:
    bar.button.event(e)

  # editing
  if bar.editable and bar.state == focusedDown:

    proc calcPart(bar: GuiBar, pos: Coord): float =
      return case bar.direction:
      of Direction.leftRight:
        pos.x - bar.pos.x
      of Direction.rightLeft:
        bar.pos.x + bar.dim.w.float - pos.x
      of Direction.topBottom:
        pos.y - bar.pos.y
      of Direction.bottomTop:
        bar.pos.y + bar.dim.h.float - pos.y

    let maxPart = case bar.direction:
    of Direction.leftRight, Direction.rightLeft:
      bar.dim.w.float
    of Direction.topBottom, Direction.bottomTop:
      bar.dim.h.float

    var
      part: float
      change: bool = false

    if bar.button == nil:
      if e.kind == MouseButtonDown:
        let pos = (e.button.x.float, e.button.y.float)
        if pos.pointInRect(bar.pos, bar.dim):
          part = bar.calcPart(pos)
          change = true
      elif e.kind == MouseMotion:
        let pos = (e.motion.x.float, e.motion.y.float)
        if pos.pointInRect(bar.pos, bar.dim):
          part = bar.calcPart(pos)
          change = true

    elif not(bar.button.wasPressed == 0):
      if e.kind == MouseMotion:
        part = bar.calcPart((e.motion.x.float, e.motion.y.float))
        change = true

    if change:
      if part < 0:
        part = 0
      elif part >= maxPart:
        part = maxPart
      bar.value = bar.min + (part / maxPart) * (bar.max - bar.min)


method event*(bar: GuiBar, e: Event) =
  bar.eventGuiBar(e)


proc renderGuiBar*(bar: GuiBar) =
  ##  Default progress bar render procedure.
  ##
  ##  Call it from your progress bar render method.
  ##
  # background
  if bar.showBg:
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
  let
    value = (bar.value - bar.min) / (bar.max - bar.min)
    part: Coord = case bar.direction:
    of Direction.leftRight, Direction.rightLeft:
      (int(bar.dim.w.float * value), bar.dim.h)
    of Direction.bottomTop, Direction.topBottom:
      (bar.dim.w, int(bar.dim.h.float * value))

  if bar.showFg and bar.value > 0:
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

  # text and button

  # update text
  if not(bar.fText == nil):
    bar.fText.setText(formatEng(
      bar.value,
      precision = bar.precision,
      decimalSep = bar.decimalSep) & bar.unit)

  # no button
  if bar.button == nil:

    # text only
    if not(bar.fText == nil):
      let offset = bar.dim / 2.0 - Coord(bar.fText.dim) / 2.0
      bar.fText.draw(bar.pos + offset)

  # button
  else:

    # updated text on button
    if bar.buttonText and not(bar.fText == nil):
      bar.button.image = bar.fText
      bar.button.centrifyImage()

    # draw button
    let buttonCenter: Coord = bar.button.sprite.dim / 2
    bar.button.pos = case bar.direction:
    of Direction.leftRight:
      bar.pos - buttonCenter + part * (1.0, 0.5)
    of Direction.rightLeft:
      bar.pos - buttonCenter + part * (-1.0, 0.5) + (bar.dim.w.float, 0.0)
    of Direction.topBottom:
      bar.pos - buttonCenter + part * (0.5, 1.0)
    of Direction.bottomTop:
      bar.pos - buttonCenter + part * (0.5, -1.0) + (0.0, bar.dim.h.float)

    bar.button.renderGuiButton()



method render*(bar: GuiBar) =
  bar.renderGuiBar()


# DEPRECATED

type GuiProgressBar* {.deprecated: "Use GuiBar instead".} = GuiBar


template initGuiProgressBar*(
    bar: GuiBar, dim: Dim, bgColor, fgColor: Color, font: Font,
    bgGraphic: TextureGraphic = nil, fgGraphic: TextureGraphic = nil,
    button: GuiButton = nil, buttonText: bool = false) {.
    deprecated: "Use initGuiBar() instead".} =
  initGuiBar(bar, dim, bgColor, fgColor, font, bgGraphic, fgGraphic,
             button, buttonText)


template init*(bar: GuiBar,
    dim: Dim, bgColor, fgColor: Color, font: Font,
    bgGraphic, fgGraphic: TextureGraphic) {.
    deprecated: "Use initGuiBar() instead".} =
  initGuiBar(bar, dim, bgColor, fgColor, font, bgGraphic, fgGraphic)


template newGuiProgressBar*(
    dim: Dim, bgColor: Color, fgColor: Color, font: Font = nil,
    bgGraphic: TextureGraphic = nil, fgGraphic: TextureGraphic = nil,
    button: GuiButton = nil, buttonText: bool = false): GuiBar {.
      deprecated: "Use newGuiBar() instead".} =
  newGuiBar(dim, bgColor, fgColor, font, bgGraphic, fgGraphic,
            button, buttonText)


template newProgressBar*(dim: Dim, bgColor: Color, fgColor: Color,
    font: Font = nil, bgGraphic: TextureGraphic = nil,
    fgGraphic: TextureGraphic = nil): GuiBar {.
      deprecated: "Use newGuiBar() instead".} =
  newGuiBar(dim, bgColor, fgColor, font, bgGraphic, fgGraphic)


template renderGuiProgressBar*(bar: GuiBar) {.
    deprecated: "Use renderGuiBar() instead".} =
  renderGuiBar(bar)

