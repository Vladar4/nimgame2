import
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/indexedimage,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types


type
  MainScene = ref object of Scene
    idximg: IndexedImage
    knightG: TextureGraphic
    knight: Entity


proc initMainScene*(scene: MainScene) =
  scene.initScene()

  scene.idximg = newIndexedImage("../assets/gfx/knight.gif")

  scene.knightG = newTextureGraphic()
  discard scene.knightG.assignTexture scene.idximg.render()

  scene.knight = newEntity()
  scene.knight.graphic = scene.knightG
  scene.knight.pos = (128, 128)

  # add to scene
  scene.add(scene.knight)


proc free*(scene: MainScene) =
  scene.knightG.free()


proc newMainScene*(): MainScene =
  new result, free
  result.initMainScene()


method event*(scene: MainScene, event: Event) =
  scene.eventScene(event)
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()
  discard box((4, 60), (220, 76), 0x000000CC'u32)
  discard string(
    (8, 64), "QWER - increase RGBA values (1st color)", 0xFFFFFFFF'u32)
  discard string(
    (8, 72), "ASDF - decrease RGBA values (1st color)", 0xFFFFFFFF'u32)
  discard string(
    (8, 80), "TYUI - increase RGBA values (2nd color)", 0xFFFFFFFF'u32)
  discard string(
    (8, 88), "GHJK - decrease RGBA values (2nd color)", 0xFFFFFFFF'u32)
  discard string(
    (8, 96), "1st: " & $scene.idximg.palette[3], 0xFFFFFFFF'u32)
  discard string(
    (8, 104), "2nd: " & $scene.idximg.palette[11], 0xFFFFFFFF'u32)


const
  Step = 15


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  let palette = scene.idximg.palette
  var
    upd = false
    color1 = palette[3]
    color2 = palette[11]

  # color1
  if ScancodeQ.pressed:
    color1.r = clamp(color1.r.int + Step, 0, 255).uint8
    upd = true
  if ScancodeW.pressed:
    color1.g = clamp(color1.g.int + Step, 0, 255).uint8
    upd = true
  if ScancodeE.pressed:
    color1.b = clamp(color1.b.int + Step, 0, 255).uint8
    upd = true
  if ScancodeR.pressed:
    color1.a = clamp(color1.a.int + Step, 0, 255).uint8
    upd = true
  if ScancodeA.pressed:
    color1.r = clamp(color1.r.int - Step, 0, 255).uint8
    upd = true
  if ScancodeS.pressed:
    color1.g = clamp(color1.g.int - Step, 0, 255).uint8
    upd = true
  if ScancodeD.pressed:
    color1.b = clamp(color1.b.int - Step, 0, 255).uint8
    upd = true
  if ScancodeF.pressed:
    color1.a = clamp(color1.a.int - Step, 0, 255).uint8
    upd = true

  # color2
  if ScancodeT.pressed:
    color2.r = clamp(color2.r.int + Step, 0, 255).uint8
    upd = true
  if ScancodeY.pressed:
    color2.g = clamp(color2.g.int + Step, 0, 255).uint8
    upd = true
  if ScancodeU.pressed:
    color2.b = clamp(color2.b.int + Step, 0, 255).uint8
    upd = true
  if ScancodeI.pressed:
    color2.a = clamp(color2.a.int + Step, 0, 255).uint8
    upd = true
  if ScancodeG.pressed:
    color2.r = clamp(color2.r.int - Step, 0, 255).uint8
    upd = true
  if ScancodeH.pressed:
    color2.g = clamp(color2.g.int - Step, 0, 255).uint8
    upd = true
  if ScancodeJ.pressed:
    color2.b = clamp(color2.b.int - Step, 0, 255).uint8
    upd = true
  if ScancodeK.pressed:
    color2.a = clamp(color2.a.int - Step, 0, 255).uint8
    upd = true

  if upd:
    scene.idximg.palette[3] = color1
    scene.idximg.palette[11] = color2
    discard scene.knightG.assignTexture(scene.idximg.render())

