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
  CountMin = 100
  CountMax = 50_000
  CountStep = 100
  CountStart = 500


type
  MainScene = ref object of Scene
    spacemanG: TextureGraphic
    spacemanP: SpacemanPhysics
    count: int

  SpacemanPhysics = ref object of Physics


method update*(physics: SpacemanPhysics, entity: Spaceman, elapsed: float) =
  physics.updatePhysics(entity, elapsed)

  # Screen collision
  if entity.pos.x < 0:
    entity.vel.x *= -1
  if entity.pos.y < 0:
    entity.vel.y *= -1
  if entity.pos.x >= game.size.w.float:
    entity.vel.x *= -1
  if entity.pos.y >= game.size.h.float:
    entity.vel.y *= -1


proc init*(scene: MainScene) =
  Scene(scene).init()
  scene.spacemanG = newTextureGraphic()
  discard scene.spacemanG.load("../assets/gfx/spaceman.png")
  scene.spacemanP = new SpacemanPhysics
  scene.count = CountStart
  for i in 1..scene.count:
    scene.list.add(newSpaceman(scene, scene.spacemanG, scene.spacemanP))


proc free*(scene: MainScene) =
  scene.spacemanG.free


proc newMainScene*(): MainScene =
  new result, free
  result.init()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    of K_Up:
      if scene.count < CountMax:
        scene.count += CountStep
        for i in scene.list.len..scene.count-1:
          scene.list.add(newSpaceman(scene, scene.spacemanG, scene.spacemanP))
    of K_Down:
      if scene.count > CountMin:
        scene.count -= CountStep
        for i in scene.count..(scene.list.len - 1):
          discard scene.list.pop()
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

