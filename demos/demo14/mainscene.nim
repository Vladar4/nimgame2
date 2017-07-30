import
  parseutils,
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/emitter,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/tilemap,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/tween,
  nimgame2/types,
  nimgame2/utils,
  dwarf


type
  MainScene = ref object of Scene
    dG, tilesG, sparkG: TextureGraphic
    d: Dwarf
    sparks: Emitter
    map: TileMap


proc init*(scene: MainScene) =
  Scene(scene).init()

  # Spark
  scene.sparkG = newTextureGraphic()
  discard scene.sparkG.load("../assets/gfx/puff.png")

  # TileMap
  scene.tilesG = newTextureGraphic()
  discard scene.tilesG.load("../assets/gfx/tile0.png")
  scene.map = newTileMap()
  scene.map.tags.add("map")
  scene.map.graphic = scene.tilesG
  scene.map.initSprite((24, 24))
  scene.map.map = loadCSV[int](
    "../assets/csv/map0.csv",
    proc(input: string): int = discard parseInt(input, result))
  scene.map.pos = (8.0, 0.0)

  # Dwarf
  scene.dG = newTextureGraphic()
  discard scene.dG.load("../assets/gfx/dwarf.png")
  scene.d = newDwarf(scene.dG, scene.map)
  scene.d.layer = 10

  # Add to scene
  scene.add(scene.d)
  scene.add(scene.map)

proc free*(scene: MainScene) =
  scene.dG.free


proc newMainScene*(): MainScene =
  new result, free
  result.init()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
      case event.key.keysym.sym:
      of K_Escape:
        gameRunning = false
      of K_F10:
        showInfo = not showInfo
      else: discard


method render*(scene: MainScene) =
  scene.renderScene()


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if scene.d.tween != nil:
    scene.d.tween.update(elapsed)

  # Controls and speed
  var direction: dwarf.Direction =
    if ScancodeDown.down or ScancodeS.down: dDown
    elif ScancodeUp.down or ScancodeW.down: dUp
    elif ScancodeLeft.down or ScancodeA.down: dLeft
    elif ScancodeRight.down or ScancodeD.down: dRight
    else: dNone

  scene.d.move(direction)

  # Sparks
  if scene.sparks == nil:
    if scene.map.map[scene.d.virtualPos.y][scene.d.virtualPos.x] == 2:
      scene.sparks = newEmitter(scene)
      scene.sparks.pos = ((scene.d.virtualPos.x.float,
                           scene.d.virtualPos.y.float) * Step) +
                           ScreenOffset + scene.d.center - (0.0, Step)
      scene.sparks.randomVel = (25.0, 25.0)
      scene.sparks.randomAcc = (10.0, 10.0)
      scene.sparks.randomTTL = 2.5
      scene.sparks.particle = newParticle()
      scene.sparks.particle.graphic = scene.sparkG
      scene.sparks.particle.initSprite((5, 5))
      scene.sparks.particle.centrify()
      discard scene.sparks.particle.addAnimation("play", toSeq(0..4), 1/5)
      scene.sparks.particle.play("play", 1, kill = true)
      scene.add(scene.sparks)
  else:
    scene.sparks.emit(10)


