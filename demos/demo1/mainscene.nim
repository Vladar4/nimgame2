import
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  spaceman


const
  NumMin = 100
  NumMax = 50_000
  NumStep = 100
  NumStart = 500


type
  MainScene = ref object of Scene
    spacemanG: TextureGraphic
    num: int


proc spacemanPhysics*(entity: Entity, elapsed: float) =
  defaultPhysics(entity, elapsed)

  # Screen collision
  if entity.pos.x < 0:
    entity.vel.x *= -1
  if entity.pos.y < 0:
    entity.vel.y *= -1
  if entity.pos.x >= game.size.w.float:
    entity.vel.x *= -1
  if entity.pos.y >= game.size.h.float:
    entity.vel.y *= -1


proc initMainScene*(scene: MainScene) =
  scene.initScene()
  scene.spacemanG = newTextureGraphic()
  discard scene.spacemanG.load("../assets/gfx/spaceman.png")
  scene.num = NumStart
  for i in 1..scene.num:
    scene.add(newSpaceman(scene, scene.spacemanG, spacemanPhysics))


proc free*(scene: MainScene) =
  scene.spacemanG.free


proc newMainScene*(): MainScene =
  new result, free
  result.initMainScene()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    of K_Up:
      if scene.num < NumMax:
        scene.num += NumStep
        for i in scene.count..scene.num-1:
          scene.add(newSpaceman(scene, scene.spacemanG, spacemanPhysics))
    of K_Down:
      if scene.num > NumMin:
        scene.num -= NumStep
        for i in scene.num..(scene.count - 1):
          discard scene.pop()
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()
  discard box((4, 60), (260, 84), 0x000000CC'u32)
  discard string(
    (8, 64), "Arrow Up - more entities", 0xFF0000FF'u32)
  discard string(
    (8, 72), "Arrow Down - less entities", 0xFF0000FF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)

