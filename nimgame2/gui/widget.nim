# nimgame2/gui/widget.nim
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


##  GUI events order:
##  #################
##
##  On mouse button down:
##
##  * press
##
##  On mouse button up:
##
##  * release
##  * click
##  * enter or leave (depending on the "modal" state)
##

import
  ../entity,
  ../graphic,
  ../input,
  ../types


type
  GuiAction* = proc(widget: GuiWidget, mb: MouseButton)

  GuiState* {.pure.} = enum
    defaultUp
    defaultDown
    focusedUp
    focusedDown
    disabledUp
    disabledDown

  GuiWidget* = ref object of Entity
    # Private
    fState: GuiState
    fWasPressed: MouseState
    # Public
    actions*: seq[GuiAction]##  A list of action to perform on click.
    mbAllow*: MouseState    ##  Mouse buttons allowed for interaction.
    toggle*, fToggled: bool ##  If `true`, the widget is in toggle on/off mode.


proc initGuiWidget*(widget: GuiWidget) =
  widget.initEntity()
  widget.actions = @[]
  widget.fState = GuiState.defaultUp
  widget.mbAllow.set(MouseButton.left)
  widget.fWasPressed = 0
  widget.toggle = false
  widget.fToggled = false


template init*(widget: GuiWidget) {.deprecated: "Use initGuiWidget() instead".} =
  initGuiWidget(widget)


proc newGuiWidget*(): GuiWidget =
  new result
  result.initGuiWidget()


proc state*(widget: GuiWidget): GuiState {.inline.} =
  return widget.fState


proc clickGuiWidget*(widget: GuiWidget, mb: MouseButton) =
  if not(widget.actions.len < 1):
    for action in widget.actions:
      widget.action(mb)


method click*(widget: GuiWidget, mb = MouseButton.left) {.base.} =
  widget.clickGuiWidget(mb)


template isUp*(state: GuiState): bool =
  (state.int mod 2 == 0)


template isDown*(state: GuiState): bool =
  (not isUp(state))


template isFocused*(state: GuiState): bool =
  (state in {GuiState.focusedUp, GuiState.focusedDown})


template isDisabled*(state: GuiState): bool =
  (state in {GuiState.disabledUp, GuiState.disabledDown})


template isEnabled*(state: GuiState): bool =
  (not isDisabled(state))


template toggled*(widget: GuiWidget): bool =
  widget.fToggled


proc setState*(widget: GuiWidget, val: GuiState) =
  widget.fState = if widget.toggle and widget.toggled and val.isUp:
                    GuiState(val.int + 1)
                  else:
                    val


method `state=`*(widget: GuiWidget, val: GuiState) {.base.} =
  widget.setState(val)


proc setToggled*(widget: GuiWidget, val: bool) =
  widget.fToggled = val
  if val:
    if widget.state.isUp:
      inc widget.fState
  else:
    if widget.state.isDown:
      dec widget.fState


method `toggled=`*(widget: GuiWidget, val: bool) {.base.} =
  widget.setToggled(val)


method press*(widget: GuiWidget) {.base.} =
  ##  Called automatically when the widget is pressed (mouse button down).
  ##
  discard


method release*(widget: GuiWidget) {.base.} =
  ##  Called automatically when the widget is released (mouse button up).
  ##
  discard


method enter*(widget: GuiWidget) {.base.} =
  ##  Called when the widget is entered (focused "modally").
  ##
  discard


method leave*(widget: GuiWidget) {.base.} =
  ##  Called when the widget is left, (unfocused "modally").
  ##
  discard


proc disable*(widget: GuiWidget) =
  if widget.toggled:
    if widget.state.isUp:
      widget.state = GuiState.disabledUp
    else:
      widget.state = GuiState.disabledDown
  else:
    widget.state = GuiState.disabledUp


proc enable*(widget: GuiWidget) =
  if widget.state == GuiState.disabledUp:
    widget.state = GuiState.defaultUp
  elif widget.state == GuiState.disabledDown:
    widget.state = GuiState.defaultDown


proc updateFocus(widget: GuiWidget, mouse: Coord): bool =
  ##  Check if the ``mouse`` is over the ``widget``.
  ##
  if widget.collider != nil:
    if mouse.collide(widget.collider):
      widget.state = GuiState.focusedUp
      return true
    else:
      widget.state = GuiState.defaultUp
      return false


proc eventGuiWidget*(widget: GuiWidget, e: Event) =
  if widget.state.isEnabled:
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
          widget.press()

    of MouseButtonUp:
      let mouse: Coord = (e.button.x.float, e.button.y.float)
      let btn = e.button.button.MouseButton
      if widget.updateFocus(mouse):
        # check if button was pressed over this widget
        if btn.down(widget.fWasPressed):
          widget.fWasPressed.set(btn, false)
          # 1 - release
          widget.release()
          # 2 - toggle
          if widget.toggle:
            widget.toggled = not widget.toggled
            widget.state = if widget.toggled: GuiState.focusedDown
                           else: GuiState.focusedUp
          # 3 - click
          widget.click(btn)
          # 4 - enter
          widget.enter()
      else:
        # mouse isn't over the widget
        if widget.toggled:
          widget.leave()
        if btn.down(widget.fWasPressed):
          widget.fWasPressed.set(btn, false)

    else:
      discard
    widget.state = widget.state


method event*(widget: GuiWidget, e: Event) =
  widget.eventGuiWidget(e)

