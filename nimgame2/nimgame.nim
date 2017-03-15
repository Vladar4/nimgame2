# nimgame2/nimgame.nim
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
  math, parseutils, random,
  sdl2/sdl,
  sdl2/sdl_image as img,
  sdl2/sdl_ttf as ttf,
  sdl2/sdl_mixer as mix,
  audio, count, draw, input, entity, scene, settings, types, utils


type
  Game* = ref object
    # Private
    fWindow: sdl.Window
    fLogicalSize: Dim
    fScale: Coord
    fIcon: sdl.Surface
    # Scene
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
    icon: string,
    imageFlags: cint = img.InitPNG,
    mixerFlags: cint = mix.InitOGG,
    mixerChannels: int = 32
    ): bool =
  ##  Init game.
  ##
  ##  ``w``, ``h``      window dimensions
  ##  ``title``         window title
  ##  ``bgColor``       window background color
  ##  ``windowFlags``   sdl window flags
  ##  ``rendererFlags`` sdl renderer flags
  ##  ``scaleQuality``  scale quality (pixel sampling)
  ##  ``imageFlags``    sdl_image flags
  ##  ``mixerFlags``    sdl_mixer flags
  ##  ``mixerChannels`` Number of channels to allocate for mixing.
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  game.fLogicalSize.w = w
  game.fLogicalSize.h = h
  game.fScale = (1.0, 1.0)
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

  # Init SDL_mixer
  if mix.init(mixerFlags) == 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL_mixer: %s", mix.getError())
    return false

  # Open mixer
  if mix.openAudio(mix.DefaultFrequency,
                   mix.DefaultFormat,
                   mix.DefaultChannels,
                   2048) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't open mixer: %s", mix.getError())
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

  if icon.len > 0:
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

  # Initialize the random number generator
  randomize()

  return true


proc newGame*(): Game =
  new result, free


template title*(game: Game): string =
  $game.fWindow.getWindowTitle()


template `title=`*(game: Game, title: string) =
  game.fWindow.setWindowTitle(title)


proc pos*(game: Game): Coord {.inline.} =
  var x, y: cint
  game.fWindow.getWindowPosition(addr(x), addr(y))
  return (x.float, y.float)


proc `pos=`*(game: Game, pos: Coord,
             centerX = false, centerY = false) =
  if (pos != game.pos) or centerX or centerY:
    let
      x = if centerX: sdl.WindowPosCentered else: pos.x.cint
      y = if centerY: sdl.WindowPosCentered else: pos.y.cint
    game.fWindow.setWindowPosition(x, y)


proc size*(game: Game): Dim =
  ##  ``Return`` game window dimensions.
  ##
  var w, h: cint
  game.fWindow.getWindowSize(addr(w), addr(h))
  return (w.int, h.int)


proc `size=`*(game: Game, dim: Dim) {.inline.} =
  if dim != game.size:
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


template setBordered*(game: Game, enabled: bool) =
  game.fWindow.setWindowBordered(enabled)


template setResizable*(game: Game, enabled: bool) =
  game.fWindow.setWindowResizable(enabled)


template show*(game: Game) =
  game.fWindow.showWindow()


template hide*(game: Game) =
  game.fWindow.hideWindow()


template focus*(game: Game) =
  game.fWindow.raiseWindow()


template maximize*(game: Game) =
  game.fWindow.maximizeWindow()


template minimize*(game: Game) =
  game.fWindow.minimizeWindow()


template restore*(game: Game) =
  game.fWindow.restoreWindow()


proc logicalSize*(game: Game): Dim {.inline.} =
  ##  Get logical size of the game renderer.
  ##
  return game.fLogicalSize


proc `logicalSize=`*(game: Game, size: Dim) =
  ##  Set logical size of the game renderer.
  ##
  if renderer.renderSetLogicalSize(size.w, size.h) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't set logical size of the game renderer: %s",
        sdl.getError())
    return
  game.fLogicalSize = size
  let size = game.size
  game.fScale.x = size.w / game.fLogicalSize.w
  game.fScale.y = size.h / game.fLogicalSize.h


proc scale*(game: Game): Coord {.inline.} =
  ##  ``Return`` the scale of the game renderer.
  ##
  return game.fScale


proc `scale=`*(game: Game, scale: Coord) =
  ##  Set scale of the game renderer.
  ##
  if renderer.renderSetScale(scale.x, scale.y) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't set renderer scale: %s",
      sdl.getError())
    return
  game.fScale = scale
  let size = game.size
  game.fLogicalSize.w = int(size.w.float / game.fScale.x)
  game.fLogicalSize.h = int(size.h.float / game.fScale.y)


proc `scale=`*(game: Game, scale: float) =
  ##  Set scale of the game renderer
  ##  (both horizontal and vertical to same value)
  ##
  game.scale = (scale, scale)


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


proc run*(game: Game) =
  ##  Start the game.
  ##
  if gameRunning:
    sdl.logError(sdl.LogCategoryError, "Already running")
    return

  gameRunning = true

  # Init FPS and UPS managers
  var
    fpsMgr = newCountMgr()
    upsMgr = newCountMgr()
    timePrev, timeCurr: uint64
    elapsed, lag, msPerFrame: int

  let
    updateIntervalSec = updateInterval / 1000

  fpsMgr.start()
  upsMgr.start()
  timePrev = sdl.getPerformanceCounter()
  draw.setFont()

  # Main loop
  while gameRunning:
    timeCurr = sdl.getPerformanceCounter()
    elapsed = timeDiff(timePrev, timeCurr)
    timePrev = timeCurr
    lag += elapsed

    # Events handling
    initKeyboard()
    initMouse()
    var event: sdl.Event
    while sdl.pollEvent(addr(event)) != 0:
      if event.kind == sdl.Quit:
        gameRunning = false
        break
      else:
        updateKeyboard(event)
        updateMouse(event)
        game.fScene.event(event)


    # Update
    var updateCounter = 0
    while lag >= updateInterval:
      if not gamePaused:
        game.fScene.update(updateIntervalSec)
      lag -= updateInterval
      inc(updateCounter)

    # Update playlist
    if not (playlist == nil):
      playlist.update()

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
        (8, 8), $fpsMgr.current & " FPS", 0xFFFFFFFF'u32)
      # Show updates per second
      discard string(
        (8, 16), $upsMgr.current & " updates per second", 0xFFFFFFFF'u32)
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
    fpsMgr.update()
    upsMgr.update()
  # while game.running

  # Free
  free(fpsMgr)
  free(upsMgr)
  free(game)

