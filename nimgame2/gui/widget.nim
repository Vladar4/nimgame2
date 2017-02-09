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
    enabledMouseButtons*: MouseButtonState
    fWasPressed: MouseButtonState


proc init*(widget: GuiWidget) =
  widget.initEntity()
  widget.fState = GuiState.default
  widget.enabledMouseButtons[MouseButton.left] = true


proc newGuiWidget*(): GuiWidget =
  result = new GuiWidget
  result.init()


proc state*(widget: GuiWidget): GuiState {.inline.} =
  return widget.fState


method onFocus*(widget: GuiWidget, mb = MouseButton.left) {.base.} =
  discard


method onPress*(widget: GuiWidget, mb = MouseButton.left) {.base.} =
  discard


method onClick*(widget: GuiWidget, mb = MouseButton.left) {.base.} =
  discard


proc setState*(widget: GuiWidget, val: GuiState) =
  widget.fState = val
  case val:
  of GuiState.default:
    discard
  of GuiState.focused:
    widget.onFocus()
  of GuiState.pressed:
    widget.onPress()
  of GuiState.disabled:
    discard


method `state=`*(widget: GuiWidget, val: GuiState) {.base.} =
  widget.setState(val)


proc clearPressed(widget: GuiWidget) =
  for i in widget.fWasPressed.mitems:
    i = false


proc updateGuiWidget*(widget: GuiWidget, elapsed: float) =
  widget.updateEntity(elapsed)

  if widget.state != GuiState.disabled:

    let mouse = mouse.abs

    widget.state = if mouse.collide(widget.collider): GuiState.focused
                   else: GuiState.default

    if widget.state == GuiState.focused:

      var mbState = mouseButtonState()

      # ignore non-enalbed buttons
      for i in MouseButton:
        if not widget.enabledMouseButtons[i]:
          mbState[i] = false

      if true in mbState:
        widget.state = GuiState.pressed

      elif true in widget.fWasPressed:
        for i in MouseButton:
          if widget.fWasPressed[i]:
            widget.onClick(i)
        widget.clearPressed

      widget.fWasPressed = mbState


method update*(widget: GuiWidget, elapsed: float) =
  widget.updateGuiWidget(elapsed)
