# nimgame2/gui/widget.nim
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
  ../input,
  ../types


type
  GuiState* {.pure.} = enum
    default
    focused
    pressed
    disabled


  GuiWidget* = ref object of Entity
    fState: GuiState
    mbAllow*, fWasPressed: MouseState


proc init*(widget: GuiWidget) =
  widget.initEntity()
  widget.fState = GuiState.default
  widget.mbAllow.set(MouseButton.left)
  widget.fWasPressed = 0


proc newGuiWidget*(): GuiWidget =
  new result
  result.init()


proc state*(widget: GuiWidget): GuiState {.inline.} =
  return widget.fState


method onPress*(widget: GuiWidget) {.base.} =
  discard


method onClick*(widget: GuiWidget, mb = MouseButton.left) {.base.} =
  discard


proc setState*(widget: GuiWidget, val: GuiState) =
  widget.fState = val
  case val:
  of GuiState.default:
    discard
  of GuiState.focused:
    discard
  of GuiState.pressed:
    widget.onPress()
  of GuiState.disabled:
    discard


method `state=`*(widget: GuiWidget, val: GuiState) {.base.} =
  widget.setState(val)


proc updateGuiWidget*(widget: GuiWidget, elapsed: float) =
  widget.updateEntity(elapsed)

  if widget.state != GuiState.disabled:

    let mouse = mouse.abs

    widget.state = if mouse.collide(widget.collider): GuiState.focused
                   else: GuiState.default

    # check buttons only if the mouse is over the widget
    if widget.state == GuiState.focused:

      for i in MouseButton:
        # ignore non-enalbed buttons
        if not i.down(widget.mbAllow):
          continue

        if widget.fWasPressed == 0: # wasn't pressed
          if i.pressed:
            widget.state = GuiState.pressed
            widget.fWasPressed.set(i)
            widget.onPress

        elif i.down(widget.fWasPressed): # i was pressed
          if i.released:
            widget.fWasPressed.set(i, false)
            widget.onClick(i)
          elif i.down(mbState):
            widget.state = GuiState.pressed
          else:
            widget.fWasPressed.set(i, false)


method update*(widget: GuiWidget, elapsed: float) =
  widget.updateGuiWidget(elapsed)

