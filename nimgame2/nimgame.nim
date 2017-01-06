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
  count, draw, input, scene, settings, types


type
  Game* = ref object
    # Private
    fSize, fLogicalSize: Dim
    fScale: Coord
    fTitle: string
    # Scene
    scene*: Scene   ##  Current scene


var
  game*: Game ##  global game variable


proc free*(game: Game) =
  renderer.destroyRenderer()
  window.destroyWindow()
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
    imageFlags: cint = img.InitPNG,
    mixerFlags: cint = mix.InitOGG
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
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  game.fSize.w = w
  game.fSize.h = h
  game.fLogicalSize.w = w
  game.fLogicalSize.h = h
  game.fScale = (1.0, 1.0)
  game.fTitle = title
  background = bgColor

  # Default options
  gameRunning = false
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

  # Create window
  window = sdl.createWindow(
    game.fTitle,
    sdl.WindowPosUndefined, sdl.WindowPosUndefined,
    game.fSize.w, game.fSize.h,
    windowFlags)
  if window == nil:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't create window: %s", sdl.getError())
    return false

  # Create renderer
  renderer = sdl.createRenderer(window, -1, rendererFlags)
  if renderer == nil:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't create renderer: %s", sdl.getError())
    return false

  # Set renderer logical size
  if renderer.renderSetLogicalSize(game.fSize.w, game.fSize.h) != 0:
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


proc size*(game: Game): Dim {.inline.} =
  ##  ``Return`` game window dimensions.
  return game.fSize


proc title*(game: Game): string {.inline.} =
  ##  ``Return`` game window title.
  return game.fTitle


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
  game.fScale.x = game.fSize.w / game.fLogicalSize.w
  game.fScale.y = game.fSize.h / game.fLogicalSize.h


proc scale*(game: Game): Coord {.inline.} =
  ##  Get scale of the game renderer.
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
  game.fLogicalSize.w = int(game.fSize.w.float / game.fScale.x)
  game.fLogicalSize.h = int(game.fSize.h.float / game.fScale.y)


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
    var event: sdl.Event
    while sdl.pollEvent(addr(event)) != 0:
      if event.kind == sdl.Quit:
        gameRunning = false
        break
      else:
        updateKeyboard(event)
        updateMouse(event)
        game.scene.event(event)


    # Update
    var updateCounter = 0
    while lag >= updateInterval:
      game.scene.update(updateIntervalSec)
      lag -= updateInterval
      inc(updateCounter)

    # Limit FPS
    if fpsLimit > 0:
      msPerFrame = 1000 div fpsLimit
      if lag < msPerFrame:
        sdl.delay(uint32(msPerFrame - lag))

    # Clear screen
    discard renderer.setRenderDrawColor(background)
    discard renderer.renderClear()

    # Render scene
    if not (game.scene == nil):
      game.scene.render()

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
        (8, 32), $game.scene.list.len & " entities", 0xFFFFFFFF'u32)
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

