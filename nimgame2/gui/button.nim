# nimgame2/button.nim
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
  ../graphic,
  ../types,
  widget


type
  GuiButton* = ref object of GuiWidget
    image*: Graphic ##  The graphic to render on top of a button
    imageOffset*: Coord ##  Image drawing offset from button's center. \
      ##  Calcuclated automatically if the image is passed in ``init()``
    imageShift*: Coord  ##  Image shift when button is pressed


proc init*(button: GuiButton,
           graphic: Graphic,
           image: Graphic = nil,
           circle: bool = false) =
  ##  GuiButton initialization.
  ##
  ##  ``graphic`` 2x2 button graphic: default, focused, pressed, disabled.
  ##
  ##  ``image`` The graphic to render on top of a butotn.
  ##
  ##  ``circle`` Set to `true` if you want a circle shape instead of square one.
  ##
  GuiWidget(button).init()
  button.graphic = graphic
  button.initSprite((graphic.dim.w / 2, graphic.dim.h / 3))
  button.image = image
  button.imageOffset = if not (image == nil):
                         (button.sprite.dim / 2 - image.dim / 2)
                       else:
                         (0, 0)
  button.imageShift = (1, 1)
  # Collider
  button.collider = if circle:
      button.newCircleCollider(
        button.sprite.dim / 2,
        max(button.sprite.dim.w, button.sprite.dim.h) / 2)
    else:
      button.newBoxCollider(
        button.sprite.dim / 2,
        button.sprite.dim)


proc newGuiButton*(graphic: Graphic,
                   image: Graphic = nil,
                   circle: bool = false): GuiButton =
  ##  Create a new GuiButton.
  ##
  ##  ``graphic`` 2x3 button graphic:
  ##  defaultUp, defaultDown, focusedUp, focusedDown, disabledUp, disabledDown.
  ##
  ##  ``image`` The graphic to render on top of a butotn.
  ##
  ##  ``circle`` Set to `true` if you want a circle shape instead of square one.
  ##
  result = new GuiButton
  result.init(graphic, image, circle)


method `state=`*(button: GuiButton, val: GuiState) =
  button.setState(val)
  button.sprite.currentFrame = val.int


proc renderGuiButton*(button: GuiButton) =
  ##  Default button render procedure.
  ##
  ##  Call it from your button render method.
  ##
  button.renderEntity()
  if not (button.image == nil):
    var pos = button.absPos + button.imageOffset
    if button.state.isDown:
      pos += button.imageShift
    button.image.draw(pos,
                      button.absRot,
                      button.absScale,
                      button.center,
                      button.flip)


method render*(button: GuiButton) =
  button.renderGuiButton()

