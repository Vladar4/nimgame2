import
  parseutils,
  sdl2/sdl,
  nimgame2/nimgame,
  nimgame2/collider,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/tilemap,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  nimgame2/utils


type
  MainScene = ref object of Scene
    tilesG, spacemanG: TextureGraphic
    camera, spaceman: Entity
    map: TileMap


proc init*(scene: MainScene) =
  Scene(scene).init()

  scene.camera = newEntity()

  # Tiles Graphic
  scene.tilesG = newTextureGraphic()
  discard scene.tilesG.load("../assets/gfx/tile0.png")

  # TileMap
  scene.map = newTileMap(scaleFix = true)
  scene.map.tags.add("map")
  scene.map.graphic = scene.tilesG
  scene.map.initSprite((24, 24))
  scene.map.map = loadCSV[int]("../assets/csv/map_camera_test.csv",
    proc(s: string): int = discard parseInt(s, result))
  scene.map.passable.add(0)
  scene.map.initCollider()
  scene.map.pos = (0.0, 0.0)
  scene.map.parent = scene.camera

  # SpacemanG
  scene.spacemanG = newTextureGraphic()
  discard scene.spacemanG.load("../assets/gfx/spaceman.png")

  # Spaceman
  scene.spaceman = newEntity()
  scene.spaceman.parent = scene.map
  scene.spaceman.graphic = scene.spacemanG
  scene.spaceman.centrify()
  scene.spaceman.pos = (200.0, 200.0)

  # Add
  scene.add(scene.spaceman)
  scene.add(scene.map)
  scene.add(scene.camera)



proc free*(scene: MainScene) =
  scene.tilesG.free()
  scene.spacemanG.free()


proc newMainScene*(): MainScene =
  new result, free
  result.init()


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
  discard box((4, 60), (300, 100), 0x000000CC'u32)

  discard string((8, 64), "Arrows - move camera", 0xFFFFFFFF'u32)
  discard string((8, 72), "WSAD - move spaceman", 0xFFFFFFFF'u32)

  discard string((8, 80), "camera.pos = " & $(-scene.camera.pos),
    0xFFFFFFFF'u32)
  discard string((8, 88), "spaceman.pos = " & $(scene.spaceman.pos),
    0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  let move = 100 * elapsed
  if ScancodeUp.down: scene.camera.pos.y += move
  if ScancodeDown.down: scene.camera.pos.y -= move
  if ScancodeLeft.down: scene.camera.pos.x += move
  if ScancodeRight.down: scene.camera.pos.x -= move
  if ScancodeW.down: scene.spaceman.pos.y -= move
  if ScancodeS.down: scene.spaceman.pos.y += move
  if ScancodeA.down: scene.spaceman.pos.x -= move
  if ScancodeD.down: scene.spaceman.pos.x += move

