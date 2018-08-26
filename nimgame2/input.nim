# nimgame2/input.nim
# Copyright (c) 2016-2018 Vladimir Arabadzhi (Vladar)
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
  sdl2/sdl,
  types, utils


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
  mWheel: Coord
  mWheelDirection: int


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
  mWheel = (0.0, 0.0)


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
  elif event.kind == MouseWheel:
    mWheelDirection = if event.wheel.direction == MouseWheelNormal: 1
                      else: -1
    # In order for mouse wheel to be consistant across platforms
    # we have to normalize the mouse wheel direction
    mWheel += Coord(
      (event.wheel.x.float, event.wheel.y.float) * mWheelDirection)


template mouse*(): Coord2 =
  ##  ``Return`` current mouse position.
  ##
  m


template mouseWheel*(): Coord =
  ## ``Return`` current mouse wheel motion.
  ##
  mWheel


template mouseWheelFlipped*(): bool =
  ## ``Return`` `true` if mouse wheel direction is flipped.
  ##
  (mWheelDirection < 0)


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


template down*(button: MouseButton, state: MouseState = mBtn): bool =
  down(int32(button), state)


template pressed*(button: int32): bool =
  ##  Check if mouse ``button`` was just pressed.
  ##
  (sdl.button(button) and mPressed) > 0


template pressed*(button: MouseButton): bool =
  pressed(int32(button))


template released*(button: int32): bool =
  ##  Check if mouse ``button`` was just released.
  ##
  (sdl.button(button) and mReleased) > 0


template released*(button: MouseButton): bool =
  released(int32(button))


template clearPressed*(button: int32) =
  ##  Remove ``button`` from pressed buttons list.
  ##
  mPressed.set(button, false)


template clearPressed*(button: MouseButton) =
  clearPressed(int32(button))


template clearReleased*(button: int32) =
  ##  Remove ``button`` from released buttons list.
  ##
  mReleased.set(button, false)


template clearReleased*(button: MouseButton) =
  clearReleased(int32(button))


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


#==========#
# Joystick #
#==========#

export
  sdl.numJoysticks, sdl.HatPosition, sdl.JoystickGUID


type
  JoyAxis* = range[low(int16)..high(int16)]
  JoyBall* = CoordInt
  JoyHat*  = sdl.HatPosition

  Joystick = ref object
    joy: sdl.Joystick
    guid: sdl.JoystickGUID
    numButtons, numAxes, numBalls, numHats: int
    pressed, released: array[uint8.high.int, int]

var
  joysticks: seq[Joystick]


proc joyIsOpened*(id: int): bool =
  if id >= 0:
    if joysticks.high < id:
      return false
    if joysticks[id] == nil:
      return false
    return true
  else:
    return joysticks.len > 0


iterator opened(joys: seq[Joystick]): Joystick =
  for i in 0..joys.high:
    if joys[i] == nil:
      continue
    yield joys[i]


proc getId*(guid: JoystickGUID): int =
  ##  ``Return`` the index of a joystick with a corresponding ``guid``,
  ##  or `-1` otherwise.
  ##
  for i in 0..joysticks.high:
    if not (joysticks[i] == nil):
      if joysticks[i].guid == guid:
        return i
  return -1


proc joyGuid*(id: int): JoystickGUID {.inline.} =
  if joyIsOpened(id):
    return joysticks[id].guid


proc openJoystick*(id: int): bool =
  let joy = joystickOpen(id)
  if joy == nil:
    return false
  # init a new joystick
  let newJoystick = new Joystick
  newJoystick.joy = joy
  newJoystick.guid = joystickGetGUID(joy)
  newJoystick.numButtons = joystickNumButtons(joy)
  newJoystick.numAxes = joystickNumAxes(joy)
  newJoystick.numBalls = joystickNumBalls(joy)
  newJoystick.numHats = joystickNumHats(joy)
  # add to the ``joysticks`` sequence
  #if joysticks == nil:
  #  joysticks = @[]
  if joysticks.high >= id:
    if not (joysticks[id] == nil):
      joystickClose(joysticks[id].joy)
    joysticks[id] = newJoystick
  else:
    while joysticks.high < id:
      joysticks.add(nil)
    joysticks[id] = newJoystick
  return true


proc closeJoystick*(id: int): bool =
  if joysticks.high < id:
    return false
  if joysticks[id] == nil:
    return false
  joystickClose(joysticks[id].joy)
  joysticks[id] = nil
  return true


proc initJoysticks*() =
  ##  Init the ``joysticks`` sequence.
  ##
  ##  Called automatically from the main game cycle.
  ##
  #if joysticks == nil:
  #  joysticks = @[]
  #else:
  for j in joysticks.opened:
    for i in 0..<j.numButtons:
      j.pressed[i] = 0
      j.released[i] = 0


proc updateJoysticks*(event: Event) =
  ##  Called automatically from the main game cycle.
  ##
  if event.kind == JoyButtonDown:
    let id = event.jbutton.which
    if joysticks.high >= id:
      let btn = event.jbutton.button
      inc joysticks[id].pressed[btn]

  elif event.kind == JoyButtonUp:
    let id = event.jbutton.which
    if joysticks.high >= id:
      let btn = event.jbutton.button
      inc joysticks[id].released[btn]


proc joyName*(joystick: int): string =
  ##  ``Return`` the name of the ``joystick``, or an empty string otherwise.
  ##
  if not joyIsOpened(joystick):
    return ""
  let name = joysticks[joystick].joy.joystickName()
  return if name == nil: "Unknown Joystick"
         else: $name


proc joyNumButtons*(joystick: int): int {.inline.} =
  if not joyIsOpened(joystick):
    return 0
  joysticks[joystick].numButtons


proc joyNumAxes*(joystick: int): int {.inline.} =
  if not joyIsOpened(joystick):
    return 0
  joysticks[joystick].numAxes


proc joyNumBalls*(joystick: int): int {.inline.} =
  if not joyIsOpened(joystick):
    return 0
  joysticks[joystick].numBalls


proc joyNumHats*(joystick: int): int {.inline.} =
  if not joyIsOpened(joystick):
    return 0
  joysticks[joystick].numHats


proc joyDown*(joystick: int, button: int): bool =
  ##  Check if ``joystick`` ``button`` is down.
  ##
  ##  ``joystick``  Joystick ID, or `-1` to check every opened joystick.
  ##
  ##  ``button``  Button ID.
  ##
  if not joyIsOpened(joystick):
    return false
  if joystick >= 0:
    if button < joysticks[joystick].numButtons:
      return joysticks[joystick].joy.joystickGetButton(button) > 0
    else:
      return false
  else:
    for j in joysticks.opened:
      if button < j.numButtons:
        if j.joy.joystickGetButton(button) > 0:
          return true
    return false


proc joyPressed*(joystick: int, button: int): bool =
  ##  Check if ``joystick`` ``button`` was just pressed.
  ##
  ##  ``joystick``  Joystick ID, or `-1` to check every opened joystick.
  ##
  ##  ``button``  Joystick button ID.
  ##
  if not joyIsOpened(joystick):
    return false
  if joystick >= 0:
    if button < joysticks[joystick].numButtons:
      return button in joysticks[joystick].pressed
    else:
      return false
  else:
    for j in joysticks.opened:
      if button < j.numButtons:
        if j.pressed[button] > 0:
          return true
    return false


proc joyReleased*(joystick: int, button: int): bool =
  ##  Check if ``joystick`` ``button`` was just released.
  ##
  ##  ``joystick``  Joystick ID, or `-1` to check every opened joystick.
  ##
  ##  ``button``  Joystick button ID.
  ##
  if not joyIsOpened(joystick):
    return false
  if joystick >= 0:
    if button < joysticks[joystick].numButtons:
      return button in joysticks[joystick].released
    else:
      return false
  else:
    for j in joysticks.opened:
      if button < j.numButtons:
        if j.released[button] > 0:
          return true
    return false


proc joyAxis*(joystick: int, axis: int): JoyAxis =
  ##  Get ``joystick`` ``axis`` current position.
  ##
  ##  ``joystick``  Joystick ID.
  ##
  ##  ``axis``  Joystick axis ID.
  ##
  if joystick < 0:
    return 0
  if not joyIsOpened(joystick):
    return 0
  let j = joysticks[joystick]
  if axis >= j.numAxes:
    return 0
  return joystickGetAxis(j.joy, axis)


proc joyBall*(joystick: int, ball: int): JoyBall =
  ##  Get ``joystick`` ``ball`` axis change since the last poll.
  ##
  ##  ``joystick``  Joystick ID.
  ##
  ##  ``ball``  Joystick ball ID.
  ##
  if joystick < 0:
    return (0, 0)
  if not joyIsOpened(joystick):
    return (0, 0)
  let j = joysticks[joystick]
  if ball >= j.numBalls:
    return (0, 0)
  var dx, dy: cint
  if joystickGetBall(j.joy, ball, addr(dx), addr(dy)) != 0:
    return (0, 0)
  return (dx.int, dy.int)


proc joyHat*(joystick: int, hat: int): JoyHat =
  ##  Get ``joystick`` ``hat`` current position.
  ##
  ##  ``joystick``  Joystick ID.
  ##
  ##  ``hat`` Joystick hat ID.
  ##
  if joystick < 0:
    return HatCentered
  if not joyIsOpened(joystick):
    return HatCentered
  let j = joysticks[joystick]
  if hat >= j.numHats:
    return HatCentered
  return joystickGetHat(j.joy, hat)


#===============#
# General Input #
#===============#

import
  tables


export
  tables


type
  GeneralInputKeyboard* = object
    key*: Scancode

  GeneralInputDirection* = enum dirX, dirY

  GeneralInputMouseKind* = enum mButton, mMove
  GeneralInputMouse* = object
    case kind*: GeneralInputMouseKind
    of mButton: button*: MouseButton
    of mMove: direction*: GeneralInputDirection

  GeneralInputJoystickKind* = enum jButton, jAxis, jBall, jHat
  GeneralInputJoystick* = object
    guid*: JoystickGUID
    case kind*: GeneralInputJoystickKind
    of jButton: button*: int
    of jAxis: axis*: int
    of jBall:
      ball*: int
      ballDirection*: GeneralInputDirection
    of jHat:
      hat*: int
      hatPosition*: HatPosition

  GeneralInputKind* = enum giKeyboard, giMouse, giJoystick
  GeneralInput* = object
    case kind*: GeneralInputKind
    of giKeyboard:
      keyboard*: GeneralInputKeyboard
    of giMouse:
      mouse*: GeneralInputMouse
    of giJoystick:
      joystick*: GeneralInputJoystick

  InputMap* = OrderedTableRef[string, GeneralInput]


proc newInputMap*(): InputMap =
  new result
  result[] = initOrderedTable[string, GeneralInput]()


proc addKey*(map: InputMap, name: string,
             key: Scancode) {.inline.} =
  map[name] = GeneralInput(kind: giKeyboard,
    keyboard: GeneralInputKeyboard(
      key: key))


proc addMouseButton*(map: InputMap, name: string,
                     button: MouseButton) {.inline.} =
  map[name] = GeneralInput(kind: giMouse,
    mouse: GeneralInputMouse(
      kind: mButton, button: button))


proc addMouseMove*(map: InputMap, name: string,
                   direction: GeneralInputDirection) {.inline.} =
  map[name] = GeneralInput(kind: giMouse,
    mouse: GeneralInputMouse(
      kind: mMove, direction: direction))


proc addJoyButton*(map: InputMap, name: string, guid: JoystickGUID,
                   button: int) {.inline.} =
  map[name] = GeneralInput(kind: giJoystick,
    joystick: GeneralInputJoystick(
      guid: guid, kind: jButton, button: button))


proc addJoyAxis*(map: InputMap, name: string, guid: JoystickGUID,
                 axis: int) {.inline.} =
  map[name] = GeneralInput(kind: giJoystick,
    joystick: GeneralInputJoystick(
      guid: guid, kind: jAxis, axis: axis))


proc addJoyBall*(map: InputMap, name: string, guid: JoystickGUID,
                 ball: int, ballDirection: GeneralInputDirection) {.inline.} =
  map[name] = GeneralInput(kind: giJoystick,
    joystick: GeneralInputJoystick(
      guid: guid, kind: jBall, ball: ball, ballDirection: ballDirection))


proc addJoyHat*(map: InputMap, name: string, guid: JoystickGUID,
                hat: int, hatPosition: HatPosition) {.inline.} =
  map[name] = GeneralInput(kind: giJoystick,
    joystick: GeneralInputJoystick(
      guid: guid, kind: jHat, hat: hat, hatPosition: hatPosition))


const GISep = ' '
template quoted(s: string): string = "\"" & s & "\""
proc `$`*(gi: GeneralInput): string =
  return case gi.kind:
    of giKeyboard:
      "KEY" & GISep & toUpperAscii($getScancodeName(gi.keyboard.key)).quoted
    of giMouse:
      case gi.mouse.kind:
      of mButton: "MBTN" & GISep & toUpperAscii($gi.mouse.button)
      of mMove: "MMOVE" & GISep & (
        case gi.mouse.direction:
        of dirX: "X"
        of dirY: "Y")
    of giJoystick:
      let id = gi.joystick.guid.getId()
      "JOY" & GISep & $id & GISep & (case gi.joystick.kind:
        of jButton: "BTN" & GISep & $gi.joystick.button
        of jAxis: "AXIS" & GISep & $gi.joystick.axis
        of jBall: "BALL" & GISep & $gi.joystick.ball & GISep & (
          case gi.joystick.ballDirection:
          of dirX: "X"
          of dirY: "Y")
        of jHat: "HAT" & GISep & $gi.joystick.hat & GISep & (
          case gi.joystick.hatPosition:
          of HatCentered: "C"
          of HatUp: "U"
          of HatRight: "R"
          of HatRightUp: "RU"
          of HatDown: "D"
          of HatRightDown: "RD"
          of HatLeft: "L"
          of HatLeftUp: "LU"
          of HatLeftDown: "LD"))


proc load*(map: InputMap, filename: string): bool =
  result = true
  let csv = loadCSV[string](filename,
                            proc(input: string): string = input,
                            GISep)
  if csv.len < 1:
    return false

  var
    count = 0
    ids: seq[int] = @[]
    guids: seq[JoystickGUID] = @[]

  for line in csv:
    if line.len < 3:
      continue
    if line[0] == "JOY": # joystick GUID definition
      if line.len < 4: continue
      if line[2] != "GUID": continue
      let id = (try: line[1].parseInt except: -1)
      if id < 0: continue
      let guid = joystickGetGUIDFromString(line[3])
      ids.add(id)
      guids.add(guid)
      continue

    let name = line[0]
    case line[1]:
    of "KEY":
      let code = getScancodeFromName(line[2])
      if code == ScancodeUnknown: continue
      map.addKey(name, code)

    of "MBTN":
      case line[2]:
      of "LEFT": map.addMouseButton(name, MouseButton.left)
      of "MIDDLE": map.addMouseButton(name, MouseButton.middle)
      of "RIGHT": map.addMouseButton(name, MouseButton.right)
      of "X1": map.addMouseButton(name, MouseButton.x1)
      of "X2": map.addMouseButton(name, MouseButton.x2)
      else: continue

    of "MMOVE":
      case line[2]:
      of "X": map.addMouseMove(name, dirX)
      of "Y": map.addMouseMove(name, dirY)
      else: continue

    of "JOY":
      if line.len < 5: continue
      let id = (try: line[2].parseInt except: -1)
      if id < 0: continue
      let i = ids.find(id)
      if i < 0: continue
      let guid = guids[i]
      let value = (try: line[4].parseInt except: -1)
      if value < 0: continue
      case line[3]:
      of "BTN": map.addJoyButton(name, guid, value)
      of "AXIS": map.addJoyAxis(name, guid, value)
      of "BALL":
        if line.len < 6: continue
        case line[5]:
        of "X": map.addJoyBall(name, guid, value, dirX)
        of "Y": map.addJoyBall(name, guid, value, dirY)
        else: continue
      of "HAT":
        if line.len < 6: continue
        case line[5]:
        of "C":   map.addJoyHat(name, guid, value, HatCentered)
        of "U":   map.addJoyHat(name, guid, value, HatUp)
        of "R":   map.addJoyHat(name, guid, value, HatRight)
        of "RU":  map.addJoyHat(name, guid, value, HatRightUp)
        of "D":   map.addJoyHat(name, guid, value, HatDown)
        of "RD":  map.addJoyHat(name, guid, value, HatRightDown)
        of "L":   map.addJoyHat(name, guid, value, HatLeft)
        of "LU":  map.addJoyHat(name, guid, value, HatLeftUp)
        of "LD":  map.addJoyHat(name, guid, value, HatLeftDown)
        else: continue
      else: continue
    else:
      continue

    inc count

  if count < 1:
    return false


proc save*(map: InputMap, filename: string): bool =
  result = true
  var f: File
  if not f.open(filename, fmWrite):
    return false
  var guids: seq[JoystickGUID] = @[]
  for pair in map.pairs:
    if pair[1].kind == giJoystick:
      if pair[1].joystick.guid notin guids:
        f.write("JOY" & GISep)
        f.write($pair[1].joystick.guid.getId() & GISep)
        f.write("GUID" & GISep)
        var s = alloc0(33 * sizeof(cchar))
        pair[1].joystick.guid.joystickGetGUIDString(cast[cstring](s), 33)
        f.write($cast[cstring](s) & "\n")
        s.dealloc()
        guids.add(pair[1].joystick.guid)
    f.write(pair[0].quoted & GISep)
    f.write($pair[1] & "\n")
  f.close()


proc down*(gi: GeneralInput): bool =
  return case gi.kind:
    of giKeyboard: gi.keyboard.key.down()
    of giMouse:
      case gi.mouse.kind:
      of mButton: gi.mouse.button.down()
      else: false
    of giJoystick:
      let id = gi.joystick.guid.getId()
      if id < 0: false  # no such joystick opened
      else:
        case gi.joystick.kind:
        of jButton:
          joyDown(id, gi.joystick.button)
        of jHat:
          gi.joystick.hatPosition == joyHat(id, gi.joystick.hat)
        else: false


proc pressed*(gi: GeneralInput): bool =
  return case gi.kind:
    of giKeyboard: gi.keyboard.key.pressed()
    of giMouse:
      case gi.mouse.kind:
      of mButton: gi.mouse.button.pressed()
      else: false
    of giJoystick:
      let id = gi.joystick.guid.getId()
      if id < 0: false  # no such joystick opened
      else:
        case gi.joystick.kind:
        of jButton:
          joyPressed(id, gi.joystick.button)
        of jHat:
          gi.joystick.hatPosition == joyHat(id, gi.joystick.hat)
        else: false


proc released*(gi: GeneralInput): bool =
  return case gi.kind:
    of giKeyboard: gi.keyboard.key.released()
    of giMouse:
      case gi.mouse.kind:
      of mButton: gi.mouse.button.released()
      else: false
    of giJoystick:
      let id = gi.joystick.guid.getId()
      if id < 0: false  # no such joystick opened
      else:
        case gi.joystick.kind:
        of jButton:
          joyReleased(id, gi.joystick.button)
        else: false


proc movement*(gi: GeneralInput): int =
  return case gi.kind:
    of giMouse:
      case gi.mouse.kind:
      of mMove:
        case gi.mouse.direction:
        of dirX: mouse.rel.x.int
        of dirY: mouse.rel.y.int
      else: 0
    of giJoystick:
      let id = gi.joystick.guid.getId()
      if id < 0: 0  # no such joystick opened
      else:
        case gi.joystick.kind:
        of jAxis: joyAxis(id, gi.joystick.axis)
        of jBall:
          case gi.joystick.ballDirection:
          of dirX: joyBall(id, gi.joystick.ball).x
          of dirY: joyBall(id, gi.joystick.ball).y
        else: 0
    else: 0

