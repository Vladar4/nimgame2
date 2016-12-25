import
  math,
  nimgame2/nimgame,
  nimgame2/collider,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/graphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  cursor, earth, spaceman


type
  MainScene = ref object of Scene
    cursorG, earthG, spacemanG: Graphic
    c: Cursor
    e: Earth
    s: Spaceman


proc init*(scene: MainScene) =
  Scene(scene).init()

  # Cursor
  scene.c = newCursor()
  scene.cursorG = newGraphic()
  discard scene.cursorG.load(game.renderer, "../assets/gfx/cursor.png")
  scene.c.graphic = scene.cursorG
  scene.c.collider = newCollider(scene.c)
  scene.list.add(scene.c)

  # Earth
  scene.e = newEarth()
  scene.earthG = newGraphic()
  discard scene.earthG.load(game.renderer, "../assets/gfx/earth.png")
  scene.e.graphic = scene.earthG
  let radius = scene.e.graphic.dim.w.float / 2
  scene.e.collider = newCircleCollider(scene.e, (radius, radius), radius)
  scene.list.add(scene.e)

  # Spaceman
  scene.s = newSpaceman()
  scene.spacemanG = newGraphic()
  discard scene.spacemanG.load(game.renderer, "../assets/gfx/spaceman.png")
  scene.s.graphic = scene.spacemanG
  scene.s.collider = newBoxCollider(scene.s, (0, 0), scene.s.graphic.dim)
  scene.list.add(scene.s)


proc free*(scene: MainScene) =
  scene.earthG.free
  scene.spacemanG.free


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


proc generateCollisionString(name: string, list: seq[string]): string =
  if list.len > 0:
    result = name & " collides with: "
    for tag in list:
      result.add(tag & ", ")
    result = result[0 .. ^3]
  else:
    result = name & " isn't colliding with anything"


method render*(scene: MainScene, renderer: Renderer) =
  scene.renderScene(renderer)
  discard renderer.box((4, 60), (320, 108), 0x000000CC'u32)

  discard renderer.string(
    (8, 64), generateCollisionString("Cursor", scene.c.collidedWith),
    0xFFFFFFFF'u32)

  discard renderer.string(
    (8, 72), generateCollisionString("Earth", scene.e.collidedWith),
    0xFFFFFFFF'u32)

  discard renderer.string(
    (8, 80), generateCollisionString("Spaceman", scene.s.collidedWith),
    0xFFFFFFFF'u32)

  discard renderer.string(
    (8, 96), "(Arrows control Spaceman, Space - toggle outlines)",
    0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if ScancodeRight.pressed: scene.s.pos.x += 1
  if ScancodeLeft.pressed: scene.s.pos.x -= 1
  if ScancodeDown.pressed: scene.s.pos.y += 1
  if ScancodeUp.pressed: scene.s.pos.y -= 1

