import
  math,
  nimgame2/nimgame,
  nimgame2/collider,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  cursor, earth, line, poly1, poly2, poly3, poly9, spaceman


type
  MainScene = ref object of Scene
    cursorG, earthG, spacemanG: TextureGraphic
    c: Cursor
    e: Earth
    d1, d2: Line
    s: Spaceman
    p1: Poly1
    p2: Poly2
    p3: Poly3
    p9: Poly9


proc init*(scene: MainScene) =
  Scene(scene).init()

  # Cursor
  scene.c = newCursor()
  scene.cursorG = newTextureGraphic()
  discard scene.cursorG.load("../assets/gfx/cursor.png")
  scene.c.graphic = scene.cursorG
  scene.c.collider = newCollider(scene.c)

  # Line 1
  scene.d1 = newLine()
  scene.d1.pos = (50.0, 420.0)
  scene.d1.center = (25.0, 0.0)
  scene.d1.collider = scene.d1.newLineCollider((-25, 0), (25, 0))

  # Line 2
  scene.d2 = newLine()
  scene.d2.pos = (50.0, 450.0)
  scene.d2.collider = scene.d2.newLineCollider((0, 0), (100, 0))

  # Earth
  scene.e = newEarth()
  scene.earthG = newTextureGraphic()
  discard scene.earthG.load("../assets/gfx/earth.png")
  scene.e.graphic = scene.earthG
  let radius = scene.earthG.dim.w.float / 2
  scene.e.collider = newCircleCollider(scene.e, (radius, radius), radius)

  # Spaceman
  scene.s = newSpaceman()
  scene.spacemanG = newTextureGraphic()
  discard scene.spacemanG.load("../assets/gfx/spaceman.png")
  scene.s.graphic = scene.spacemanG
  scene.s.centrify()
  scene.s.collider = newBoxCollider(scene.s, (0, 0), scene.spacemanG.dim)

  # Poly1
  scene.p1 = newPoly1()
  scene.p1.pos = (350, 160)

  # Poly2
  scene.p2 = newPoly2()
  scene.p2.pos = (350, 210)

  # Poly3
  scene.p3 = newPoly3()
  scene.p3.pos = (350, 260)

  # Poly9
  scene.p9 = newPoly9()
  scene.p9.pos = (350, 360)

  # add to scene
  scene.list.add(scene.d1)
  scene.list.add(scene.d2)
  scene.list.add(scene.e)
  scene.list.add(scene.s)
  scene.list.add(scene.c)
  scene.list.add(scene.p1)
  scene.list.add(scene.p2)
  scene.list.add(scene.p3)
  scene.list.add(scene.p9)


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


method render*(scene: MainScene) =
  scene.renderScene()
  discard box((4, 60), (380, 140), 0x000000CC'u32)

  discard string(
    (8, 64), generateCollisionString("Cursor", scene.c.collidedWith),
    0xFFFFFFFF'u32)

  discard string(
    (8, 72), generateCollisionString("Line", scene.d1.collidedWith),
    0xFFFFFFFF'u32)

  discard string(
    (8, 80), generateCollisionString("Earth", scene.e.collidedWith),
    0xFFFFFFFF'u32)

  discard string(
    (8, 88), generateCollisionString("Spaceman", scene.s.collidedWith),
    0xFFFFFFFF'u32)

  discard string(
    (8, 96), generateCollisionString("Poly9", scene.p9.collidedWith),
    0xFFFFFFFF'u32)

  discard string(
    (8, 120), "Space toggles outlines, Arrows control spaceman",
    0xFFFFFFFF'u32)

  discard string(
    (8, 128), "WASDQE control line, IJKLUO control polygon",
    0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  # Spaceman
  if ScancodeRight.pressed: scene.s.pos.x += 1
  if ScancodeLeft.pressed: scene.s.pos.x -= 1
  if ScancodeDown.pressed: scene.s.pos.y += 1
  if ScancodeUp.pressed: scene.s.pos.y -= 1
  # Line
  if ScancodeD.pressed: scene.d1.pos.x += 1
  if ScancodeA.pressed: scene.d1.pos.x -= 1
  if ScancodeS.pressed: scene.d1.pos.y += 1
  if ScancodeW.pressed: scene.d1.pos.y -= 1
  if ScancodeQ.pressed: scene.d1.rot -= 1
  if ScancodeE.pressed: scene.d1.rot += 1
  # Poly9
  if ScancodeL.pressed: scene.p9.pos.x += 1
  if ScancodeJ.pressed: scene.p9.pos.x -= 1
  if ScancodeK.pressed: scene.p9.pos.y += 1
  if ScancodeI.pressed: scene.p9.pos.y -= 1
  if ScancodeU.pressed: scene.p9.rot -= 1
  if ScancodeO.pressed: scene.p9.rot += 1

