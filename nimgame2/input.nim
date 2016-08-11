# nimgame2/input.nim
# Copyright (c) 2016 Vladar
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
  Button* {.size: sizeof(int32), pure.} = enum
    left = sdl.ButtonLeft,
    middle = sdl.ButtonMiddle,
    right = sdl.ButtonRight,
    x1 = sdl.ButtonX1,
    x2 = sdl.ButtonX2


var
  kbd: ptr array[sdl.NumScancodes.int, uint8]
  m: Coord2
  mBtn: int32


############
# KEYBOARD #
############

template updateKeyboard*() =
  ##  Called automatically from the main game cycle.
  ##
  kbd = sdl.getKeyboardState(nil)


template pressed*(scancode: Scancode): bool =
  ##  Check if ``scancode`` (keyboard key) is pressed.
  ##
  kbd[scancode.int] > 0'u8


template pressed*(keymod: Keymod): bool =
  ##  Check if ``keymod`` (keyboard mod key) is pressed.
  ##
  sdl.getModState() and keymod


#########
# MOUSE #
#########

template updateMouse*() =
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
  ##  Capture mouse
  sdl.captureMouse(enabled) == 0


template pressed*(button: Button): bool =
  ##  Check if mouse ``button`` is pressed.
  ##
  (sdl.button(button.int32) and mBtn) > 0


template pressed*(button: int32): bool =
  ##  Check if mouse ``button`` is pressed.
  ##
  (sdl.button(button) and mBtn) > 0

