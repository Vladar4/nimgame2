import
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/gui/button,
  nimgame2/texturegraphic,
  nimgame2/textureatlas,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types


type
  MainScene = ref object of Scene
    atlas: TextureAtlas


proc initMainScene*(scene: MainScene) =
  scene.initScene()

  scene.atlas = newTextureAtlas("../assets/gfx/atlas.png",
                                "../assets/csv/atlas.csv")

  let
    eSpaceman = newEntity()
    eGradient = newEntity()
    eButton = newGuiButton(scene.atlas["button"])
    eSprite = newEntity()

  eSpaceman.graphic = scene.atlas["spaceman"]
  eSpaceman.pos = (50.0, 100.0)

  eGradient.graphic = scene.atlas["gradient"]
  eGradient.pos = (150.0, 100.0)

  eButton.pos = (200.0, 100.0)

  eSprite.graphic = scene.atlas["sprite"]
  eSprite.initSprite((32, 32), (0, 32), (1, 1))
  discard eSprite.addAnimation("play", toSeq(0..3), 1/4)
  eSprite.play("play")
  eSprite.pos = (200.0, 150.0)

  scene.add(eSpaceman)
  scene.add(eGradient)
  scene.add(eButton)
  scene.add(eSprite)


proc free*(scene: MainScene) =
  scene.atlas.free()


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

