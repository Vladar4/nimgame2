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
    defaultUp
    defaultDown
    focusedUp
    focusedDown
    disabledUp
    disabledDown


  GuiWidget* = ref object of Entity
    fState: GuiState
    mbAllow*, fWasPressed: MouseState
    toggle*, toggled*: bool


proc init*(widget: GuiWidget) =
  widget.initEntity()
  widget.fState = GuiState.defaultUp
  widget.mbAllow.set(MouseButton.left)
  widget.fWasPressed = 0
  widget.toggle = false
  widget.toggled = false


proc newGuiWidget*(): GuiWidget =
  new result
  result.init()


proc state*(widget: GuiWidget): GuiState {.inline.} =
  return widget.fState


method onPress*(widget: GuiWidget) {.base.} =
  discard


method onClick*(widget: GuiWidget, mb = MouseButton.left) {.base.} =
  discard


template isUp*(state: GuiState): bool =
  (state.int mod 2 == 0)


template isDown*(state: GuiState): bool =
  (not isUp(state))


proc setState*(widget: GuiWidget, val: GuiState) =
  widget.fState = if widget.toggle and widget.toggled and val.isUp:
                    GuiState(val.int + 1)
                  else:
                    val


method `state=`*(widget: GuiWidget, val: GuiState) {.base.} =
  widget.setState(val)


proc updateFocus(widget: GuiWidget, mouse: Coord): bool =
  ##  Check if the ``mouse`` is over the ``widget``.
  ##
  if mouse.collide(widget.collider):
    widget.state = GuiState.focusedUp
    return true
  else:
    widget.state = GuiState.defaultUp
    return false


proc eventGuiWidget*(widget: GuiWidget, e: Event) =
  if widget.state != GuiState.disabledUp:
    case e.kind:
    of MouseMotion:
      let mouse: Coord = (e.motion.x.float, e.motion.y.float)
      if widget.updateFocus(mouse):
        for btn in MouseButton:
          # check if button is allowed
          if btn.down(widget.mbAllow):
            # check if button was pressed over this widget
            if btn.down(widget.fWasPressed):
              widget.state = GuiState.focusedDown

    of MouseButtonDown:
      let mouse: Coord = (e.button.x.float, e.button.y.float)
      if widget.updateFocus(mouse):
        let btn = e.button.button.MouseButton
        # check if button is allowed
        if btn.down(widget.mbAllow):
          widget.state = GuiState.focusedDown
          widget.fWasPressed.set(btn)
          widget.onPress()

    of MouseButtonUp:
      let mouse: Coord = (e.button.x.float, e.button.y.float)
      let btn = e.button.button.MouseButton
      if widget.updateFocus(mouse):
        # check if button was pressed over this widget
        if btn.down(widget.fWasPressed):
          # toggle
          if widget.toggle:
            widget.toggled = not widget.toggled
            widget.state = if widget.toggled:GuiState.focusedDown
                           else: GuiState.focusedUp
          #
          widget.fWasPressed.set(btn, false)
          widget.onClick(btn)
      else:
        if btn.down(widget.fWasPressed):
          widget.fWasPressed.set(btn, false)
    else:
      discard
    widget.state = widget.state


method event*(widget: GuiWidget, e: Event) =
  widget.eventGuiWidget(e)

