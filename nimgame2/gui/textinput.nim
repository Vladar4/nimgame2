# nimgame2/textinput.nim
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
  ../collider,
  ../entity,
  ../font,
  ../graphic,
  ../textgraphic,
  ../types,
  widget


type
  GuiTextInput* = ref object of GuiWidget
    font*: Font         ##  Font object for text rendering
    fText: TextGraphic
    textPos*: Coord     ##  Relative text position


proc init*(input: GuiTextInput,
           graphic: Graphic,
           font: Font) =
  ##  GuiTextInput initialization.
  ##
  ##  ``grapic`` 2x2 input field graphic:
  ##  default, focused, pressed (active), disabled.
  ##
  ##  ``font`` Font object for text rendering.
  ##
  GuiWidget(input).init()
  input.graphic = graphic
  input.initSprite(graphic.dim / 2)
  # Collider
  input.collider = input.newBoxCollider(input.sprite.dim / 2, input.sprite.dim)
  # Text
  input.fText = newTextGraphic()
  input.fText.font = font
  input.textPos = (
    (input.sprite.dim.h - font.charH) / 2,
    (input.sprite.dim.h - font.charH) / 2)
  #TODO testing
  input.fText.lines = ["Test"]


proc newGuiTextInput*(graphic: Graphic, font: Font): GuiTextInput =
  ##  Create a new GuiTextInput.
  ##
  ##  ``grapic`` 2x2 input field graphic:
  ##  default, focused, pressed (active), disabled.
  ##
  ##  ``font`` Font object for text rendering.
  ##
  result = new GuiTextInput
  result.init(graphic, font)


method `state=`*(input: GuiTextInput, val: GuiState) =
  input.setState(val)
  input.sprite.currentFrame = val.int


proc renderGuiTextInput*(input: GuiTextInput) =
  ##  Default text input render procedure.
  ##
  ##  Call it from your text input render method.
  ##
  input.renderEntity()
  input.fText.draw(input.pos + input.textPos)


method render*(input: GuiTextInput) =
  input.renderGuiTextInput()

