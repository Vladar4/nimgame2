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
  Button* {.size: sizeof(int32), pure.} = enum  ##  \
    ##  Mouse buttons.
    ##
    left = sdl.ButtonLeft,
    middle = sdl.ButtonMiddle,
    right = sdl.ButtonRight,
    x1 = sdl.ButtonX1,
    x2 = sdl.ButtonX2


var
  kbd: ptr array[sdl.NumScancodes.int, uint8]
  kbdPressed, kbdReleased: seq[Scancode]
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


template pressed*(scancode: Scancode): bool =
  ##  Check if ``scancode`` (keyboard key) was just pressed.
  ##
  (scancode in kbdPressed)


template released*(scancode: Scancode): bool =
  ##  Check if ``scancode`` (keyboard key) was just released.
  ##
  (scancode in kbdReleased)


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

template updateMouse*(event: Event) =
  ##  Called automatically from the main game cycle.
  ##
  var ax, ay, rx, ry: cint
  mBtn = sdl.getMouseState(addr(ax), addr(ay)).int
  discard sdl.getRelativeMouseState(addr(rx), addr(ry))
  m = ((ax.float, ay.float), (rx.float, ry.float))


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


template pressed*(button: Button): bool =
  ##  Check if mouse ``button`` is pressed.
  ##
  (sdl.button(button.int32) and mBtn) > 0


template pressed*(button: int32): bool =
  ##  Check if mouse ``button`` is pressed.
  ##
  (sdl.button(button) and mBtn) > 0


template cursorIsVisible*(): bool =
  ##  ``Return`` `true` if the system mouse cursor is visible,
  ##  or `false` otherwise.
  ##
  (sdl.showCursor(-1) == 1)


template showCursor*() =
  ##  Show the system mouse cursor.
  ##
  sdl.showCursor(1)


template hideCursor*() =
  ##  Hide the system mouse cursor.
  ##
  sdl.showCursor(0)


template toggleCursor*() =
  ##  Toggle the visibility of the system mouse cursor.
  ##
  sdl.showCursor(if cursorIsVisible: 0 else: 1)

