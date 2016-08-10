# nimgame2/nimgame.nim
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
  math, random,
  sdl2/sdl,
  sdl2/sdl_image as img,
  sdl2/sdl_gfx_primitives as gfx,
  sdl2/sdl_gfx_primitives_font as gfx_font,
  sdl2/sdl_ttf as ttf,
  sdl2/sdl_mixer as mix,
  count, input, scene, types


type
  Game* = ref object
    # Private
    fDim: Dim
    fTitle: string
    # Public
    bgColor*: sdl.Color     ##  Screen clearing color
    renderer*: sdl.Renderer ##  Game renderer pointer
    window*: sdl.Window     ##  Game window pointer
    #
    scene*: Scene   ##  Current scene
    #
    running*: bool  ##  If `false` - break main loop
    showInfo*: bool ##  Show info panel
    fpsLimit*: int  ##  Limit frames per second to `fpsLimit`, if `0` - no limit
    updateInterval*: int  ## Call update() each `updateInterval` ms


var
  game*: Game ##  global game variable


proc free(game: Game) =
  game.renderer.destroyRenderer()
  game.window.destroyWindow()
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
    imageFlags: cint = img.InitPNG,
    mixerFlags: cint = mix.InitMP3
    ): bool =
  ##  Init game.
  ##
  ##  ``w``, ``h``      window dimensions
  ##  ``title``         window title
  ##  ``bgColor``       window background color
  ##  ``windowFlags``   sdl window flags
  ##  ``rendererFlags`` sdl renderer flags
  ##  ``imageFlags``    sdl_image flags
  ##  ``mixerFlags``    sdl_mixer flags
  ##
  ##  ``Return`` `true` on success, `false` otherwise.
  ##
  game.fDim.w = w
  game.fDim.h = h
  game.fTitle = title
  game.bgColor = bgColor

  # Default options
  game.running = false
  game.showInfo = false
  game.fpsLimit = 0
  game.updateInterval = 10

  # Init SDL
  if sdl.init(sdl.InitEverything) != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL: %s", sdl.getError())
    return false

  # Init SDL_image
  if img.init(imageFlags) == 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL_image: %s", sdl.getError())
    return false

  # Init SDL_ttf
  if ttf.init() != 0:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't initialize SDL_ttf: %s", sdl.getError())
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
  game.window = sdl.createWindow(
    game.fTitle,
    sdl.WindowPosUndefined, sdl.WindowPosUndefined,
    game.fDim.w, game.fDim.h,
    windowFlags)
  if game.window == nil:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't create window: %s", sdl.getError())
    return false

  # Create renderer
  game.renderer = sdl.createRenderer(game.window, -1, rendererFlags)
  if game.renderer == nil:
    sdl.logCritical(
      sdl.LogCategoryError, "Can't create renderer: %s", sdl.getError())
    return false

  # Initialize the random number generator
  randomize()

  return true


proc dim*(game: Game): Dim {.inline.} =
  ##  ``Return`` game window dimensions.
  return game.fDim


proc title*(game: Game): string {.inline.} =
  ##  ``Return`` game window title.
  return game.fTitle


proc run*(game: Game) =
  ##  Start the game.
  ##
  if game.running:
    sdl.logError(sdl.LogCategoryError, "Already running")
    return

  game.running = true

  # Init FPS and UPS managers
  var
    fpsMgr = newCountMgr()
    upsMgr = newCountMgr()
    timePrev, timeCurr: uint64
    elapsed, lag, msPerFrame: int

  let
    updateIntervalSec = game.updateInterval / 1000

  fpsMgr.start()
  upsMgr.start()
  timePrev = sdl.getPerformanceCounter()
  gfx.gfxPrimitivesSetFont(addr(gfx_font.gfxPrimitivesFontData), 8, 8)

  # Main loop
  while game.running:
    timeCurr = sdl.getPerformanceCounter()
    elapsed = timeDiff(timePrev, timeCurr)
    timePrev = timeCurr
    lag += elapsed

    # Events handling
    updateKeyboard()

    var event: sdl.Event
    while sdl.pollEvent(addr(event)) != 0:
      if event.kind == sdl.Quit:
        game.running = false
        break
      else:
        game.scene.event(event)


    # Update
    var updateCounter = 0
    while lag >= game.updateInterval:
      game.scene.update(updateIntervalSec)
      lag -= game.updateInterval
      inc(updateCounter)

    # Limit FPS
    if game.fpsLimit > 0:
      msPerFrame = 1000 div game.fpsLimit
      if lag < msPerFrame:
        sdl.delay(uint32(msPerFrame - lag))

    # Clear screen
    discard game.renderer.setRenderDrawColor(game.bgColor)
    discard game.renderer.renderClear()

    # Render scene
    if not (game.scene == nil):
      game.scene.render(game.renderer)

    # Render info
    if game.showInfo:
      # Background
      discard game.renderer.boxColor(
        x1 = 4, y1 = 4, x2 = 260, y2 = 52, 0xCC000000'u32)
      # Show FPS
      discard game.renderer.stringColor(
        x = 8, y = 8, $fpsMgr.current & " FPS", 0xFFFFFFFF'u32)
      # Show updates per second
      discard game.renderer.stringColor(
        x = 8, y = 16, $upsMgr.current & " updates per second", 0xFFFFFFFF'u32)
      # Show updates per frame
      discard game.renderer.stringColor(
        x = 8, y = 24, $updateCounter & " updates per frame", 0xFFFFFFFF'u32)
      # Show entities count
      discard game.renderer.stringColor(
        x = 8, y = 32, $game.scene.list.len & " entities", 0xFFFFFFFF'u32)
      # Show memory usage
      discard game.renderer.stringColor(
        x = 8, y = 40,
        $(getOccupiedMem() shr 10) & " KB used of " &
        $(getTotalMem() shr 10) & " KB total",
        0xFFFFFFFF'u32)

    # Update renderer
    game.renderer.renderPresent()

    # Increase frame count
    fpsMgr.update()
    upsMgr.update()
  # while game.running

  # Free
  free(fpsMgr)
  free(upsMgr)
  free(game)

