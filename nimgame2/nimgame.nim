# nimgame2/nimgame.nim
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

import
  random,
  sdl2/sdl,
  sdl2/sdl_image as img,
  sdl2/sdl_ttf as ttf,
  sdl2/sdl_mixer as mix,
  audio, draw, input, scene, settings, types, utils


type
  Game* = ref object
    # Private
    fWindow: sdl.Window
    fSize: Dim
    fIcon: sdl.Surface
    # Public
    fScene: Scene   ##  Current scene


var
  game*: Game ##  Global game variable


#======#
# Game #
#======#

proc free*(game: Game) =
  renderer.destroyRenderer()
  game.fWindow.destroyWindow()
  game.fIcon.freeSurface()
  while mix.init(0) != 0: mix.quit()
  let mixNumOpened = mix.querySpec(nil, nil, nil)
  for i in 0..<mixNumOpened: mix.closeAudio()
  ttf.quit()
  img.quit()
  sdl.quit()


proc init*(
    game: Game,
    w, h: int,
    title = "Nimgame2",
    bgColor = sdl.Color(r: 0, g: 0, b: 0, a: 255),
    windowFlags: uint32 = 0,
    rendererFlags: uint32 = sdl.RendererAccelerated or sdl.RendererPresentVsync,
    scaleQuality: range[0..2] = 0,
    integerScale: bool = false,
    iconSurface: sdl.Surface = nil,
    icon: string = "",
    imageFlags: cint = img.InitPNG,
    mixerFlags: cint = mix.InitOGG,
    mixerChannels: int = 32
    ): bool =
  ##  Init game.
  ##
  ##  ``w``, ``h``      window dimensions
  ##
  ##  ``title``         window title
  ##
  ##  ``bgColor``       window background color
  ##
  ##  ``windowFlags``   sdl window flags
  ##
  ##  ``rendererFlags`` sdl renderer flags
  ##
  ##  ``scaleQuality``  scale quality (pixel sampling)
  ##
  ##  ``integerScale``  force integer scale only
  ##
  ##  ``iconSurface``   window icon surface (has priority over ``icon``)
  ##
  ##  ``icon``          window icon file name
  ##
  ##  ``imageFlags``    sdl_image flags
  ##
  ##  ``mixerFlags``    sdl_mixer flags
  ##
  ##  ``mixerChannels`` Number of channels to allocate for mixing.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  game.fSize.w = w
  game.fSize.h = h
  background = bgColor

  # Default options
  gameRunning = false
  gamePaused = false
  showInfo = false
  fpsLimit = 0
  updateInterval = 10
  colliderOutline = false
  colliderOutlineColor = sdl.Color(r: 0, g: 255, b: 0, a: 255)

  # Init SDL
  if sdl.init(sdl.InitEverything) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL: %s", sdl.getError())
    return false

  # Init SDL_image
  if img.init(imageFlags) == 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL_image: %s", img.getError())
    return false

  # Init SDL_ttf
  if ttf.init() != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL_ttf: %s", ttf.getError())
    return false

  # Open mixer
  if mix.openAudio(mix.DefaultFrequency,
                   mix.DefaultFormat,
                   mix.DefaultChannels,
                   2048) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL_mixer: %s",
      mix.getError())
    return false

  # Init SDL_mixer
  if mix.init(mixerFlags) == 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL_mixer flags: %s",
      mix.getError())
    return false

  # Allocate mixing channels
  discard allocateChannels(mixerChannels)

  # Create window
  game.fWindow = sdl.createWindow(
    title,
    sdl.WindowPosUndefined, sdl.WindowPosUndefined,
    w, h,
    windowFlags)
  if game.fWindow == nil:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't create window: %s", sdl.getError())
    return false

  if not (iconSurface == nil):
    game.fIcon = iconSurface
    game.fWindow.setWindowIcon(game.fIcon)
  elif icon.len > 0:
    game.fIcon = loadSurface(icon)
    game.fWindow.setWindowIcon(game.fIcon)

  # Create renderer
  renderer = sdl.createRenderer(game.fWindow, -1, rendererFlags)
  if renderer == nil:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't create renderer: %s", sdl.getError())
    return false

  # Set renderer logical size
  if renderer.renderSetLogicalSize(w, h) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't set logical size of the game renderer: %s",
        sdl.getError())

  # Set renderer scale quality
  discard sdl.setHint(sdl.HintRenderScaleQuality, $scaleQuality)
  discard renderer.renderSetIntegerScale(integerScale)

  # Initialize the random number generator
  randomize()

  return true


proc newGame*(): Game =
  new result, free


template flag(game: Game, flag: uint32): bool =
  ((game.fWindow.getWindowFlags() and flag) != 0)


proc title*(game: Game): string {.inline.} =
  $game.fWindow.getWindowTitle()


proc `title=`*(game: Game, title: string) {.inline.} =
  game.fWindow.setWindowTitle(title)


proc pos*(game: Game): Coord =
  var x, y: cint
  game.fWindow.getWindowPosition(addr(x), addr(y))
  return (x.float, y.float)


proc `pos=`*(game: Game, pos: Coord) =
  if pos != game.pos:
    game.fWindow.setWindowPosition(pos.x.cint, pos.y.cint)


proc centrify*(game: Game, centerX = true, centerY = true) =
  let
    x: cint = if centerX: sdl.WindowPosCentered else: game.pos.x.cint
    y: cint = if centerY: sdl.WindowPosCentered else: game.pos.y.cint
  game.fWindow.setWindowPosition(x, y)
  # check if the screen is smaller than a window
  var
    pos = game.pos
    repos = false
  if pos.x < 0:
    pos.x = 0
    repos = true
  if pos.y < 0:
    pos.y = 0
    repos = true
  if repos:
    game.pos = pos
    game.fWindow.maximizeWindow()


proc windowSize*(game: Game): Dim =
  ##  ``Return`` game window dimensions.
  ##
  var w, h: cint
  game.fWindow.getWindowSize(addr(w), addr(h))
  return (w.int, h.int)


proc `windowSize=`*(game: Game, dim: Dim) {.inline.} =
  if dim != game.windowSize:
    game.fWindow.setWindowSize(dim.w.cint, dim.h.cint)


proc minSize*(game: Game): Dim =
  var w, h: cint
  game.fWindow.getWindowMinimumSize(addr(w), addr(h))
  return (w.int, h.int)


proc `minSize=`*(game: Game, dim: Dim) =
  if dim != game.minSize:
    let
      w: cint = if dim.w > 0: dim.w else: 1
      h: cint = if dim.h > 0: dim.h else: 1
    game.fWindow.setWindowMinimumSize(w, h)


proc maxSize*(game: Game): Dim =
  var w, h: cint
  game.fWindow.getWindowMaximumSize(addr(w), addr(h))
  return (w.int, h.int)


proc `maxSize=`*(game: Game, dim: Dim) =
  if dim != game.maxSize:
    let
      w: cint = if dim.w > 0: dim.w else: 1
      h: cint = if dim.h > 0: dim.h else: 1
    game.fWindow.setWindowMaximumSize(w, h)


proc setBordered*(game: Game, enabled: bool) {.inline.} =
  game.fWindow.setWindowBordered(enabled)


proc setResizable*(game: Game, enabled: bool) {.inline.} =
  game.fWindow.setWindowResizable(enabled)


proc setFullscreen*(
    game: Game, set: bool, desktop: bool = true): bool {.inline.} =
  ##  Set fullscreen mode.
  ##
  ##  ``desktop`` use `WINDOW_FULLSCREEN_DESKTOP` flag instead of
  ##  `WINDOW_FULLSCREEN`. Default is `true`.
  ##
  ##  ``Return`` `true` on success, or `false` otherwise.
  ##
  return
    if set:
      0 == game.fWindow.setWindowFullscreen(
        if desktop: WindowFullscreenDesktop
        else: WindowFullscreen)
    else:
      0 == game.fWindow.setWindowFullscreen(0)


proc fullscreen*(game: Game): bool {.inline.} =
  ##  ``Return`` `true` if game is in fullscreen mode, or `false` otherwise.
  ##
  game.flag(WindowFullscreen) or
  game.flag(WindowFullscreenDesktop)


proc show*(game: Game) {.inline.} =
  game.fWindow.showWindow()


proc shown*(game: Game): bool {.inline.} =
  ##  ``Return`` `true` if game window is shown, or `false` otherwise.
  ##
  game.flag(WindowShown)


proc hide*(game: Game) {.inline.} =
  game.fWindow.hideWindow()


proc hidden*(game: Game): bool {.inline.} =
  ##  ``Return`` `true` if game window is hidden, or `false` otherwise.
  ##
  game.flag(WindowHidden)


proc focus*(game: Game) {.inline.} =
  game.fWindow.raiseWindow()


proc focused*(game: Game): bool {.inline.} =
  ##  ``Return`` `true` if game window has input focus, or `false` otherwise.
  ##
  game.flag(WindowInputFocus)


proc maximize*(game: Game) {.inline.} =
  game.fWindow.maximizeWindow()


proc maximized*(game: Game): bool {.inline.} =
  ##  ``Return`` `true` if game window is maximized, or `false` otherwise.
  ##
  game.flag(WindowMaximized)


proc minimize*(game: Game) {.inline.} =
  game.fWindow.minimizeWindow()


proc minimized*(game: Game): bool {.inline.} =
  ##  ``Return`` `true` if game window is minimized, or `false` otherwise.
  ##
  game.flag(WindowMinimized)


proc restore*(game: Game) {.inline.} =
  game.fWindow.restoreWindow()


proc size*(game: Game): Dim {.inline.} =
  ##  Get logical size of the game renderer.
  ##
  return game.fSize


proc scale*(game: Game): Coord {.inline.} =
  ##  ``Return`` the scale of the game renderer.
  ##
  var w, h: cfloat
  renderer.renderGetScale(addr(w), addr(h))
  return (w.float, h.float)


proc icon*(game: Game): Surface {.inline.} =
  ##  ``Return`` game icon surface.
  ##
  return game.fIcon


proc `icon=`*(game: Game, icon: string) {.inline.} =
  ##  Load new game icon from the ``icon`` file name.
  ##
  game.fIcon = loadSurface(icon)
  game.fWindow.setWindowIcon(game.fIcon)


proc `icon=`*(game: Game, surface: Surface) {.inline.} =
  ##  Set new game icon surface.
  ##
  game.fIcon = surface
  game.fWindow.setWindowIcon(game.fIcon)


proc scene*(game: Game): Scene {.inline.} =
  ##  ``Return`` current game scene.
  ##
  return game.fScene


proc `scene=`*(game: Game, val: Scene) =
  ##  Set a new game scene.
  ##
  if not (game.fScene == nil):
    game.fScene.hide()
  game.fScene = val
  game.fScene.show()


proc viewport*(game: Game): Rect =
  ##  Get current viewport.
  ##
  var rect: Rect
  renderer.renderGetViewport(addr(rect))
  return rect


proc `viewport=`*(game: Game, rect: Rect) =
  ##  Set current viewport.
  ##
  var r: sdl.Rect = rect
  if renderer.renderSetViewport(addr(r)) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't set viewport: %s",
        sdl.getError())


proc resetViewport*(game: Game) =
  ##  Set default viewport.
  ##
  if renderer.renderSetViewport(nil) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't reset viewport: %s",
        sdl.getError())


proc forceRender*(game: Game, elapsed: float = 0.0) =
  ##  Force game screen rendering outsice of the game loop.
  ##
  discard renderer.setRenderDrawColor(background)
  discard renderer.renderClear()
  if not (game.fScene == nil):
    game.fScene.update(elapsed)
    game.fScene.render()
  renderer.renderPresent()


#=====#
# RUN #
#=====#

proc run*(game: Game) =
  ##  Start the game.
  ##
  if gameRunning:
    sdl.logError(sdl.LogCategoryError, "Already running")
    return

  gameRunning = true

  # Init FPS and UPS managers, declare all needed variables
  var
    fps = newCounter()
    ups = newCounter()
    timePrev, timeCurr: uint64
    elapsed, lag, msPerFrame, updateCounter: int
    updateIntervalSec: float
    event: sdl.Event

  timePrev = sdl.getPerformanceCounter()
  draw.setFont()

  # Init input devices
  sdl.startTextInput() # for the GUI text input events
  initKeyboard()
  initMouse()
  initJoysticks()

  # Main loop
  while gameRunning:
    timeCurr = sdl.getPerformanceCounter()
    elapsed = timeDiff(timePrev, timeCurr)
    timePrev = timeCurr
    lag += elapsed
    updateIntervalSec = msToSec(updateInterval)

    # Update
    updateCounter = 0
    while lag >= updateInterval:
      if not gamePaused:
        game.fScene.update(updateIntervalSec)
        # clear inputs after the first loop
        initKeyboard()
        initMouse()
        initJoysticks()
      lag -= updateInterval
      inc(updateCounter)

    # Update playlist
    if not (playlist == nil):
      playlist.update()

    # Events handling
    while sdl.pollEvent(addr(event)) != 0:
      if event.kind == sdl.Quit:
        gameRunning = false
        break
      else:
        updateKeyboard(event)
        updateMouse(event)
        updateJoysticks(event)
        game.fScene.event(event)

    # Limit FPS
    if fpsLimit > 0:
      msPerFrame = 1000 div fpsLimit
      if lag < msPerFrame:
        sdl.delay(uint32(msPerFrame - lag))

    # Clear screen
    discard renderer.setRenderDrawColor(background)
    discard renderer.renderClear()

    # Render scene
    if not (game.fScene == nil):
      game.fScene.render()

    # Render info
    if showInfo:
      # Background
      discard box((4, 4), (260, 52), 0x000000CC'u32)
      # Show FPS
      discard string(
        (8, 8), $fps.value & " FPS", 0xFFFFFFFF'u32)
      # Show updates per second
      discard string(
        (8, 16), $ups.value & " updates per second", 0xFFFFFFFF'u32)
      # Show updates per frame
      discard string(
        (8, 24), $updateCounter & " updates per frame", 0xFFFFFFFF'u32)
      # Show entities count
      discard string(
        (8, 32), $game.fScene.count & " entities", 0xFFFFFFFF'u32)
      # Show memory usage
      discard string(
        (8, 40),
        $(getOccupiedMem() shr 10) & " KB used of " &
        $(getTotalMem() shr 10) & " KB total",
        0xFFFFFFFF'u32)

    # Update renderer
    renderer.renderPresent()

    # Increase frame count
    fps.update()
    ups.update()
  # while game.running

  # Free
  free(game)

