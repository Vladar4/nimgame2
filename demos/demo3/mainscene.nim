import
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  spaceman


type
  MainScene = ref object of Scene
    spacemanG: TextureGraphic
    s: Spaceman


proc spacemanPhysics(entity: Entity, elapsed: float) =
  defaultPhysics(entity, elapsed)
  if entity.pos.x.int < 0:
    entity.pos.x = 0
    entity.vel.x = 0
  if entity.pos.x.int > game.size.w:
    entity.pos.x = game.size.w.float
    entity.vel.x = 0
  if entity.pos.y.int < 0:
    entity.pos.y = 0
    entity.vel.y = 0
  if entity.pos.y.int > game.size.h:
    entity.pos.y = game.size.h.float
    entity.vel.y = 0


proc init*(scene: MainScene) =
  Scene(scene).init()
  # Spaceman
  scene.s = newSpaceman()
  scene.spacemanG = newTextureGraphic()
  discard scene.spacemanG.load("../assets/gfx/spaceman.png")
  scene.s.graphic = scene.spacemanG
  scene.s.physics = spacemanPhysics
  scene.s.centrify()
  scene.add(scene.s)
  # Mouse
  #discard mouseRelative(true)

proc free*(scene: MainScene) =
  scene.spacemanG.free()


proc newMainScene*(): MainScene =
  new result, free
  result.init()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    else: discard


method render*(scene: MainScene) =
  # Draw line between the spaceman and the mouse position if LMB is pressed
  if MouseButton.left.down:
    discard line(scene.s.pos, mouse.abs, 0xFF0000FF'u32)

  scene.renderScene()

  var arrows: string = ""
  if ScancodeUp.down: arrows &= "Up "
  if ScancodeDown.down: arrows &= "Down "
  if ScancodeLeft.down: arrows &= "Left "
  if ScancodeRight.down: arrows &= "Right"

  var wsad: string = ""
  if ScancodeW.down: wsad &= "W "
  if ScancodeS.down: wsad &= "S "
  if ScancodeA.down: wsad &= "A "
  if ScancodeD.down: wsad &= "D "

  var mouse: string = "Abs(" & $mouse.abs.x.int & ":" & $mouse.abs.y.int &
                      ") Rel(" & $mouse.rel.x.int & ":" & $mouse.rel.y.int & ")"

  var buttons: string = ""
  if MouseButton.left.down: buttons &= "L "
  if MouseButton.middle.down: buttons &= "M "
  if MouseButton.right.down: buttons &= "R "
  if MouseButton.x1.down: buttons &= "X1 "
  if MouseButton.x2.down: buttons &= "X2 "


  discard box((4, 60), (260, 100), 0xCC000000'u32)
  discard string(
    (8, 64), "Arrows: " & arrows, 0xFF0000FF'u32)
  discard string(
    (8, 72), "WSAD: " & wsad, 0xFF0000FF'u32)
  discard string(
    (8, 80), "Mouse: " & mouse, 0xFF0000FF'u32)
  discard string(
    (8, 88), "Mouse buttons: " & buttons, 0xFF0000FF'u32)
  discard string(
    (8, 96), "Mouse wheel: " & $mouseWheel, 0xFF0000FF'u32)

const
  Acc = 100.0


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  # Arrows and WSAD
  if ScancodeUp.down or ScancodeW.down: scene.s.vel.y -= Acc * elapsed
  if ScancodeDown.down or ScancodeS.down: scene.s.vel.y += Acc * elapsed
  if ScancodeLeft.down or ScancodeA.down: scene.s.vel.x -= Acc * elapsed
  if ScancodeRight.down or ScancodeD.down: scene.s.vel.x += Acc * elapsed
  # Mouse
  if MouseButton.left.down:
    var vector: Coord
    vector = (mouse.abs - scene.s.pos) * elapsed
    scene.s.vel += vector

