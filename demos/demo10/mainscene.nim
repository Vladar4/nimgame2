import
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
    earthG, spacemanG: TextureGraphic
    e: Earth
    s: Spaceman


proc initMainScene*(scene: MainScene) =
  scene.initScene()
  # Earth
  scene.e = newEarth()
  scene.earthG = newTextureGraphic()
  discard scene.earthG.load("../assets/gfx/earth.png")
  scene.e.graphic = scene.earthG
  # Spaceman
  scene.s = newSpaceman()
  scene.spacemanG = newTextureGraphic()
  discard scene.spacemanG.load("../assets/gfx/spaceman.png")
  scene.s.graphic = scene.spacemanG

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
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()
  discard box((4, 60), (220, 76), 0x000000CC'u32)
  discard string(
    (8, 64), "1/2 - Change layer", 0xFF0000FF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if Scancode1.down: scene.s.layer = -1
  if Scancode2.down: scene.s.layer = 1

