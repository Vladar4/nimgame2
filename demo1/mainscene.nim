import
  sdl2/sdl,
  sdl2/sdl_gfx_primitives as gfx,
  sdl2/sdl_gfx_primitives_font as gfx_font,
  ../nimgame2/nimgame,
  ../nimgame2/entity,
  ../nimgame2/graphic,
  ../nimgame2/scene,
  ../nimgame2/types,
  spaceman


const
  CountMin = 100
  CountMax = 50_000
  CountStep = 100
  CountStart = 1_000


type
  MainScene = ref object of Scene
    spacemanG: Graphic
    spacemanL: SpacemanLogic
    spacemanCenter: Coord
    count: int

  SpacemanLogic = ref object of Logic


method update*(logic: SpacemanLogic, entity: Spaceman, elapsed: float) =
  # Movement
  entity.pos.x += entity.vel.x * elapsed
  entity.pos.y += entity.vel.y * elapsed

  # Rotation
  entity.rot += entity.rotVel * elapsed
  if entity.rot >= 360.0: entity.rot -= 360.0
  elif entity.rot < 0.0: entity.rot += 360.0

  # Screen collision
  if entity.pos.x < -MainScene(entity.scene).spacemanCenter.x:
    entity.vel.x *= -1
  if entity.pos.y < -MainScene(entity.scene).spacemanCenter.y:
    entity.vel.y *= -1
  if entity.pos.x >= game.dim.w.float + MainScene(entity.scene).spacemanCenter.x:
    entity.vel.x *= -1
  if entity.pos.y >= game.dim.h.float + MainScene(entity.scene).spacemanCenter.y:
    entity.vel.y *= -1


proc init*(scene: MainScene) =
  Scene(scene).init()
  scene.spacemanG = newGraphic()
  discard scene.spacemanG.load(game.renderer, "../assets/gfx/spaceman.png")
  scene.spacemanCenter.x = scene.spacemanG.w / 2
  scene.spacemanCenter.y = scene.spacemanG.h / 2
  scene.spacemanL = new SpacemanLogic
  scene.count = CountStart
  for i in 1..scene.count:
    scene.list.add(newSpaceman(scene, scene.spacemanG, scene.spacemanL))


proc newMainScene*(): MainScene =
  result = new MainScene
  result.init()


method event*(scene: MainScene, event: sdl.Event) =
  if event.kind == sdl.KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      game.running = false
    of K_Up:
      if scene.count < CountMax:
        scene.count += CountStep
        for i in scene.list.len..scene.count-1:
          scene.list.add(newSpaceman(scene, scene.spacemanG, scene.spacemanL))
    of K_Down:
      if scene.count > CountMin:
        scene.count -= CountStep
        for i in scene.count..scene.list.high:
          discard scene.list.pop()
    else: discard


method render*(scene: MainScene, renderer: sdl.Renderer) =
  scene.renderScene(renderer)
  discard renderer.boxColor(
    x1 = 4, y1 = 60,
    x2 = 258, y2 = 84,
    0xCC000000'u32)
  discard renderer.stringColor(
    x = 8, y = 64, "Arrow Up - more entities", 0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 72, "Arrow Down - less entities", 0xFF0000FF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)

