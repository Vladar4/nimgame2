# nimgame2/input.nim
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
  sdl2/sdl,
  types


export
  sdl.Scancode, sdl.Keymod


type
  MouseButton* {.size: sizeof(int32), pure.} = enum  ##  \
    ##  Mouse buttons.
    ##
    left = sdl.ButtonLeft
    middle = sdl.ButtonMiddle
    right = sdl.ButtonRight
    x1 = sdl.ButtonX1
    x2 = sdl.ButtonX2

  MouseState* = int32


converter toInt*(button: MouseButton): int32 =
  button.int32


var
  kbd: ptr array[sdl.NumScancodes.int, uint8]
  kbdPressed, kbdReleased: seq[Scancode]
  mPressed, mReleased: int32
  m: Coord2
  mBtn: int32


#==========#
# Keyboard #
#==========#

proc initKeyboard*() =
  ##  Clear the buffers.
  ##
  ##  Called automatically from the main game cycle.
  ##
  kbdPressed = @[]
  kbdReleased = @[]


proc updateKeyboard*(event: Event) =
  ##  Called automatically from the main game cycle.
  ##
  kbd = sdl.getKeyboardState(nil)
  if event.kind == KeyDown:
    if event.key.repeat == 0:
      kbdPressed.add(event.key.keysym.scancode)
  elif event.kind == KeyUp:
    kbdReleased.add(event.key.keysym.scancode)


template down*(scancode: Scancode): bool =
  ##  Check if ``scancode`` (keyboard key) is down.
  ##
  kbd[scancode.int] > 0'u8


template down*(keymod: Keymod): bool =
  ##  Check if ``keymod`` (keyboard mod key) is down.
  ##
  sdl.getModState() and keymod


proc down*(scancodes: openarray[Scancode]): bool =
  ##  Check if any scancode in the ``scancodes`` array is down.
  ##
  for i in scancodes:
    if i.down:
      return true
  return false


proc down*(keymods: openarray[Keymod]): bool =
  ##  Check if any keymod in the ``keymodes`` array is down.
  ##
  for i in keymods:
    if i.down:
      return true
  return false


template pressed*(scancode: Scancode): bool =
  ##  Check if ``scancode`` (keyboard key) was just pressed.
  ##
  (scancode in kbdPressed)


proc pressed*(scancodes: openarray[Scancode]): bool =
  ##  Check if any scancode in the ``scancodes`` array was just pressed.
  ##
  for i in scancodes:
    if i.pressed:
      return true
  return false


template released*(scancode: Scancode): bool =
  ##  Check if ``scancode`` (keyboard key) was just released.
  ##
  (scancode in kbdReleased)


proc released*(scancodes: openarray[Scancode]): bool =
  ##  Check if any scancode in the ``scancodes`` array was just released.
  ##
  for i in scancodes:
    if i.released:
      return true
  return false


proc clearPressed*(scancode: Scancode) =
  ##  Remove ``scancode`` from pressed keys list.
  ##
  let idx = kbdPressed.find(scancode)
  if idx < 0:
    return
  kbdPressed.del(idx)


proc clearReleased*(scancode: Scancode) =
  ##  Remove ``scancode`` from released keys list.
  ##
  let idx = kbdReleased.find(scancode)
  if idx < 0:
    return
  kbdReleased.del(idx)


template name*(keycode: Keycode): string =
  ##  ``Return`` a human-readable name for the ``keycode``.
  ##
  $getKeyName(keycode)


template name*(scancode: Scancode): string =
  ##  ``Return`` a human-readable name for the ``scancode``.
  ##
  $getScancodeName(scancode)


#=======#
# Mouse #
#=======#

template set*(state: var MouseState,
              button: int32,
              enable: bool = true) =
  ##  Enable or disable specific mouse button's flag in the given ``state``.
  ##
  if enable:
    state = state or sdl.button(button).int32
  else:
    state = state and (not sdl.button(button).int32)


proc initMouse*() =
  ##  Clear the buffers.
  ##
  ##  Called automatically from the main game cycle.
  ##
  mPressed = 0
  mReleased = 0


proc updateMouse*(event: Event) =
  ##  Called automatically from the main game cycle.
  ##
  var ax, ay, rx, ry: cint
  mBtn = sdl.getMouseState(addr(ax), addr(ay)).int
  discard sdl.getRelativeMouseState(addr(rx), addr(ry))
  m = ((ax.float, ay.float), (rx.float, ry.float))

  if event.kind == MouseButtonDown:
    mPressed.set(event.button.button.int32)
  elif event.kind == MouseButtonUp:
    mReleased.set(event.button.button.int32)


template mouse*(): Coord2 =
  ##  ``Return`` current mouse position.
  ##
  m


template mouseRelative*(enabled: bool): bool =
  ##  Set relative mouse mode.
  ##
  sdl.setRelativeMouseMode(enabled) == 0


template mouseCapture*(enabled: bool): bool =
  ##  Capture or release the mouse.
  ##
  sdl.captureMouse(enabled) == 0


template down*(button: int32, state: MouseState = mBtn): bool =
  ##  Check if mouse ``button`` is pressed.
  ##
  (sdl.button(button) and state) > 0


template pressed*(button: int32): bool =
  ##  Check if mouse ``button`` was just pressed.
  ##
  (sdl.button(button) and mPressed) > 0


template released*(button: int32): bool =
  ##  Check if mouse ``button`` was just released.
  ##
  (sdl.button(button) and mReleased) > 0


template clearPressed*(button: int32) =
  ##  Remove ``button`` from pressed buttons list.
  ##
  mPressed.set(button, false)


template clearReleased*(button: int32) =
  ##  Remove ``button`` from released buttons list.
  ##
  mReleased.set(button, false)


template mbState*(): MouseState =
  ##  ``Return`` current mouse buttons state value.
  ##
  mBtn


template cursorIsVisible*(): bool =
  ##  ``Return`` `true` if the system mouse cursor is visible,
  ##  or `false` otherwise.
  ##
  (sdl.showCursor(-1) == 1)


template showCursor*() =
  ##  Show the system mouse cursor.
  ##
  discard sdl.showCursor(1)


template hideCursor*() =
  ##  Hide the system mouse cursor.
  ##
  discard sdl.showCursor(0)


template toggleCursor*() =
  ##  Toggle the visibility of the system mouse cursor.
  ##
  discard sdl.showCursor(if cursorIsVisible: 0 else: 1)

