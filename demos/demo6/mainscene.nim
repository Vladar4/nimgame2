import
  math,
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  earth, spaceman


type
  MainScene = ref object of Scene
    cursorG, earthG, spacemanG: TextureGraphic
    e: Earth
    s: Spaceman


proc initMainScene*(scene: MainScene) =
  scene.initScene()

  # Earth
  scene.e = newEarth()
  scene.earthG = newTextureGraphic()
  discard scene.earthG.load("../assets/gfx/earth.png")
  scene.e.graphic = scene.earthG
  scene.e.centrify()
  scene.e.collider = scene.e.newCircleCollider((0, 0), 128)

  # Spaceman
  scene.s = newSpaceman()
  scene.spacemanG = newTextureGraphic()
  discard scene.spacemanG.load("../assets/gfx/spaceman.png")
  scene.s.graphic = scene.spacemanG
  scene.s.centrify()
  scene.s.parent = scene.e
  scene.s.collider = scene.s.newBoxCollider((0, 0), (100, 160))

  # add to scene
  scene.add(scene.s)
  scene.add(scene.e)


proc free*(scene: MainScene) =
  scene.earthG.free
  scene.spacemanG.free


proc newMainScene*(): MainScene =
  new result, free
  result.initMainScene()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    of K_Space:
      colliderOutline = not colliderOutline
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()
  discard box((4, 60), (260, 100), 0x000000CC'u32)

  discard string((8, 64), "WASD  - move group", 0xFFFFFFFF'u32)
  discard string((8, 72), "QE    - rotate group", 0xFFFFFFFF'u32)
  discard string((8, 80), "RF    - scale group", 0xFFFFFFFF'u32)
  discard string((8, 88), "Space - toggle outlines", 0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if ScancodeD.down: scene.e.pos.x += 1
  if ScancodeA.down: scene.e.pos.x -= 1
  if ScancodeS.down: scene.e.pos.y += 1
  if ScancodeW.down: scene.e.pos.y -= 1
  if ScancodeQ.down: scene.e.rot -= 1
  if ScancodeE.down: scene.e.rot += 1
  if ScancodeR.down: scene.e.scale -= 0.01
  if ScancodeF.down: scene.e.scale += 0.01

