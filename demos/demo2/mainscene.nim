import
  sdl2/sdl_gfx_primitives as gfx,
  sdl2/sdl_gfx_primitives_font as gfx_font,
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/graphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/types,
  earth, spaceman


type
  MainScene = ref object of Scene
    earthG, spacemanG: Graphic
    e: Earth
    s: Spaceman


proc init*(scene: MainScene) =
  Scene(scene).init()
  # Earth
  scene.e = newEarth()
  scene.earthG = newGraphic()
  discard scene.earthG.load(game.renderer, "../assets/gfx/earth.png")
  scene.e.graphic = scene.earthG
  scene.list.add(scene.e)
  # Spaceman
  scene.s = newSpaceman()
  scene.spacemanG = newGraphic()
  discard scene.spacemanG.load(game.renderer, "../assets/gfx/spaceman.png")
  scene.s.graphic = scene.spacemanG
  scene.list.add(scene.s)


proc free*(scene: MainScene) =
  scene.earthG.free
  scene.spacemanG.free


proc newMainScene*(): MainScene =
  new result, free
  result.init()


proc changeBlendMod(scene: MainScene, increase = true) =
  # get blend mod
  var b = scene.s.graphic.blendMod
  # change blend mod
  if increase:
    if b.int == 0:
      b = Blend(1)
    elif b < Blend.high:
      b = Blend(b.int shl 1)
  else: # decrease
    if b.int > 0:
      b = Blend(b.int shr 1)
  # set blend mod
  scene.s.graphic.blendMod = b


const
  Resolutions = [(266, 200), (320, 240), (426, 320), (512, 384), (640, 480), (800, 600), (1024, 760), (1280, 960)]


proc changeResolution(scene: MainScene, increase = true) =
  # get current resolution
  var idx = Resolutions.find(game.logicalSize)
  # change resolution
  if increase:
    if idx < Resolutions.high:
      inc(idx)
  else: # decrease
    if idx > 0:
      dec(idx)
  # set resolution
  game.logicalSize = Resolutions[idx]


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      game.running = false
    of K_T:
      scene.changeBlendMod()
    of K_G:
      scene.changeBlendMod(false)
    of K_Y:
      scene.changeResolution()
    of K_H:
      scene.changeResolution(false)
    else: discard


method render*(scene: MainScene, renderer: Renderer) =
  scene.renderScene(renderer)
  let c = scene.s.graphic.colorMod
  let res = game.logicalSize
  discard renderer.boxColor(
    x1 = 4, y1 = 60,
    x2 = 220, y2 = 116,
    0xCC000000'u32)
  discard renderer.stringColor(
    x = 8, y = 64, "Q/A - red mod: " & $c.r,
    0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 72, "W/S - green mod: " & $c.g,
    0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 80, "E/D - blue mod: " & $c.b,
    0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 88, "R/F - alpha mod: " & $scene.s.graphic.alphaMod,
    0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 96, "T/G - blend mod: " & $scene.s.graphic.blendMod,
    0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 104, "Y/H - resolution: " & $res.w & "x" & $res.h,
    0xFF0000FF'u32)


type
  ColorElement = enum
    ceR, ceG, ceB


proc changeColorMod(scene: MainScene, elem: ColorElement, val: int) =
  var color = scene.s.graphic.colorMod
  # Get color element
  var e = int(case elem:
              of ceR: color.r
              of ceG: color.g
              of ceB: color.b)
  # Change color element
  inc(e, val)
  # Correct value
  if e < 0x00: e = 0x00
  elif e > 0xFF: e = 0xFF
  # Set color mod
  case elem:
  of ceR: color.r = e.uint8
  of ceG: color.g = e.uint8
  of ceB: color.b = e.uint8
  scene.s.graphic.colorMod = color


proc changeAlphaMod(scene: MainScene, val: int) =
  # Get alpha mod
  var a = scene.s.graphic.alphaMod.int
  # Change alpha mod
  inc(a, val)
  # Correct value
  if a < 0x00: a = 0x00
  elif a > 0xFF: a = 0xFF
  # Set alpha mod
  scene.s.graphic.alphaMod = a.uint8


method update*(scene: MainScene, elapsed: float) =
  let val = int(0xFF * elapsed)
  scene.updateScene(elapsed)
  if ScancodeQ.pressed: scene.changeColorMod(ceR, val)
  if ScancodeA.pressed: scene.changeColorMod(ceR, -val)
  if ScancodeW.pressed: scene.changeColorMod(ceG, val)
  if ScancodeS.pressed: scene.changeColorMod(ceG, -val)
  if ScancodeE.pressed: scene.changeColorMod(ceB, val)
  if ScancodeD.pressed: scene.changeColorMod(ceB, -val)
  if ScancodeR.pressed: scene.changeAlphaMod(val)
  if ScancodeF.pressed: scene.changeAlphaMod(-val)

