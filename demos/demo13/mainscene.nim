import
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
  cursor


type
  MainScene = ref object of Scene
    tilesG: TextureGraphic
    tm: TileMap
    cursor: Cursor


proc init*(scene: MainScene) =
  Scene(scene).init()

  # Cursor
  hideCursor()
  scene.cursor = newCursor()
  let cursorG = newTextureGraphic()
  discard cursorG.load("../assets/gfx/cursor.png")
  scene.cursor.graphic = cursorG
  scene.cursor.collider = newCollider(scene.cursor)
  scene.add(scene.cursor)

  # Tiles Graphic
  scene.tilesG = newTextureGraphic()
  discard scene.tilesG.load("../assets/gfx/sprite0.png")
  # TileMap
  scene.tm = newTileMap()
  scene.tm.tags.add("map")
  scene.tm.graphic = scene.tilesG
  scene.tm.initSprite((64, 64), offset = (32, 32))
  scene.tm.map = @[
    @[0, 0, 0, 0],
    @[1, 0, 0, 1],
    @[2, 3, 3, 2]
  ]
  scene.tm.passable.add(0)
  scene.tm.centrify()
  scene.tm.initCollider()
  scene.tm.pos = (320.0, 240.0)
  scene.add(scene.tm)



proc free*(scene: MainScene) =
  scene.tilesG.free()


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
  discard box((4, 60), (300, 108), 0x000000CC'u32)

  discard string((8, 64), "WSAD - move", 0xFFFFFFFF'u32)

  discard string((8, 72), "Q/E - change angle", 0xFFFFFFFF'u32)

  discard string((8, 80), "R/F - change scale", 0xFFFFFFFF'u32)

  discard string((8, 88), "Space - toggle collider outlines", 0xFFFFFFFF'u32)

  discard string((8, 96),
    if scene.cursor.collidedWith.len > 0:
      "Cursor is over a collidable tile"
    else:
      "Cursor isn't over a collidable tile",
    0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if ScancodeW.down: scene.tm.pos.y -= 1.0
  if ScancodeS.down: scene.tm.pos.y += 1.0
  if ScancodeA.down: scene.tm.pos.x -= 1.0
  if ScancodeD.down: scene.tm.pos.x += 1.0
  if ScancodeQ.down: scene.tm.rot -= 1.0
  if ScancodeE.down: scene.tm.rot += 1.0
  if ScancodeR.down: scene.tm.scale -= 0.005
  if ScancodeF.down: scene.tm.scale += 0.005

