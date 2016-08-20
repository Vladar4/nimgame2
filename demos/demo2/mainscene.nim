import
  math,
  nimgame2/nimgame,
  nimgame2/draw,
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
  ScaleMax = 3
  ScaleMin = 0.5
  ScaleMod = 0.25

proc changeResolution(scene: MainScene, increase = true) =
  # get current scale
  var scale = game.scale
  # change scale
  if increase:
    if scale.x < ScaleMax:
      scale.x += ScaleMod
      scale.y += ScaleMod
  else: # decrease
    if scale.x > ScaleMin:
      scale.x -= ScaleMod
      scale.y -= ScaleMod
  # set resolution
  game.scale = scale


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
  let scale: Coord = (game.scale.x.round(2), game.scale.y.round(2))
  discard renderer.box((4, 60), (220, 124), 0x000000CC'u32)
  discard renderer.string(
    (8, 64), "Q/A - red mod: " & $c.r, 0xFF0000FF'u32)
  discard renderer.string(
    (8, 72), "W/S - green mod: " & $c.g, 0xFF0000FF'u32)
  discard renderer.string(
    (8, 80), "E/D - blue mod: " & $c.b, 0xFF0000FF'u32)
  discard renderer.string(
    (8, 88), "R/F - alpha mod: " & $scene.s.graphic.alphaMod, 0xFF0000FF'u32)
  discard renderer.string(
    (8, 96), "T/G - blend mod: " & $scene.s.graphic.blendMod, 0xFF0000FF'u32)
  discard renderer.string(
    (8, 104), "Y/H - resolution: " & $res.w & "x" & $res.h, 0xFF0000FF'u32)
  discard renderer.string(
    (8, 112), "Scale: " & $scale.x & "x" & $scale.y, 0xFF0000FF'u32)


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

