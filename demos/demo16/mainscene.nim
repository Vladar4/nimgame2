import
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types


type
  MainScene = ref object of Scene
    spacemanG: TextureGraphic
    p0125, p025, p05, p1: Entity


proc init*(scene: MainScene) =
  Scene(scene).init()

  # Graphics
  scene.spacemanG = newTextureGraphic()
  discard scene.spacemanG.load("../assets/gfx/spaceman.png")

  # Entities
  scene.camera = newEntity()
  scene.camera.pos = game.size / 2

  scene.p0125 = newEntity()
  scene.p0125.graphic = scene.spacemanG
  scene.p0125.centrify()
  scene.p0125.pos = game.size / 2
  scene.p0125.pos.y -= 150
  scene.p0125.parallax = 0.125

  scene.p025 = newEntity()
  scene.p025.graphic = scene.spacemanG
  scene.p025.centrify()
  scene.p025.pos = game.size / 2
  scene.p025.pos.y -= 100
  scene.p025.parallax = 0.25

  scene.p05 = newEntity()
  scene.p05.graphic = scene.spacemanG
  scene.p05.centrify()
  scene.p05.pos = game.size / 2
  scene.p05.pos.y -= 50
  scene.p05.parallax = 0.5

  scene.p1 = newEntity()
  scene.p1.graphic = scene.spacemanG
  scene.p1.centrify()
  scene.p1.pos = game.size / 2

  scene.cameraBond = scene.p1

  # add to scene
  scene.add(scene.p1)
  scene.add(scene.p05)
  scene.add(scene.p025)
  scene.add(scene.p0125)


proc free*(scene: MainScene) =
  scene.spacemanG.free()


proc newMainScene*(): MainScene =
  new result, free
  result.init()


method event*(scene: MainScene, event: Event) =
  scene.eventScene(event)
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    of K_Space:
      colliderOutline = not colliderOutline
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  scene.camera.pos = mouse.abs - Coord(game.size / 2)

