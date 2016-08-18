import
  sdl2/sdl,
  sdl2/sdl_gfx_primitives as gfx,
  sdl2/sdl_gfx_primitives_font as gfx_font,
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/graphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/types,
  spaceman


type
  MainScene = ref object of Scene
    spacemanG: Graphic
    s: Spaceman


method update*(logic: Physics, entity: Spaceman, elapsed: float) =
  logic.updatePhysics(entity, elapsed)
  if entity.pos.x.int < 0: entity.pos.x = 0
  if entity.pos.x.int > game.size.w: entity.pos.x = game.size.w.float
  if entity.pos.y.int < 0: entity.pos.y = 0
  if entity.pos.y.int > game.size.h: entity.pos.y = game.size.h.float


proc init*(scene: MainScene) =
  Scene(scene).init()
  # Spaceman
  scene.s = newSpaceman()
  scene.spacemanG = newGraphic()
  discard scene.spacemanG.load(game.renderer, "../assets/gfx/spaceman.png")
  scene.s.graphic = scene.spacemanG
  scene.s.physics = new Physics
  scene.s.center.x = scene.s.graphic.size.w / 2
  scene.s.center.y = scene.s.graphic.size.h / 2
  scene.list.add(scene.s)
  # Mouse
  #discard mouseRelative(true)

proc free*(scene: MainScene) =
  scene.spacemanG.free


proc newMainScene*(): MainScene =
  new result, free
  result.init()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      game.running = false
    else: discard


method render*(scene: MainScene, renderer: Renderer) =
  # Draw line between the spaceman and the mouse position if LMB is pressed
  if Button.left.pressed:
    discard game.renderer.setRenderDrawColor(0xFF, 0x00, 0x00, 0xFF)
    discard game.renderer.renderDrawLine(scene.s.pos.x.int, scene.s.pos.y.int,
                                        mouse.abs.x.int, mouse.abs.y.int)

  scene.renderScene(renderer)

  var arrows: string = ""
  if ScancodeUp.pressed: arrows &= "Up "
  if ScancodeDown.pressed: arrows &= "Down "
  if ScancodeLeft.pressed: arrows &= "Left "
  if ScancodeRight.pressed: arrows &= "Right"

  var wsad: string = ""
  if ScancodeW.pressed: wsad &= "W "
  if ScancodeS.pressed: wsad &= "S "
  if ScancodeA.pressed: wsad &= "A "
  if ScancodeD.pressed: wsad &= "D "

  var mouse: string = "Abs(" & $mouse.abs.x.int & ":" & $mouse.abs.y.int &
                      ") Rel(" & $mouse.rel.x.int & ":" & $mouse.rel.y.int & ")"

  var buttons: string = ""
  if Button.left.pressed: buttons &= "L "
  if Button.middle.pressed: buttons &= "M "
  if Button.right.pressed: buttons &= "R "
  if Button.x1.pressed: buttons &= "X1 "
  if Button.x2.pressed: buttons &= "X2 "


  discard renderer.boxColor(
    x1 = 4, y1 = 60,
    x2 = 260, y2 = 100,
    0xCC000000'u32)
  discard renderer.stringColor(
    x = 8, y = 64, "Arrows: " & arrows,
    0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 72, "WSAD: " & wsad,
    0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 80, "Mouse: " & mouse,
    0xFF0000FF'u32)
  discard renderer.stringColor(
    x = 8, y = 88, "Mouse buttons: " & buttons,
    0xFF0000FF'u32)

const
  Acc = 100.0


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  # Arrows and WSAD
  if ScancodeUp.pressed or ScancodeW.pressed: scene.s.vel.y -= Acc * elapsed
  if ScancodeDown.pressed or ScancodeS.pressed: scene.s.vel.y += Acc * elapsed
  if ScancodeLeft.pressed or ScancodeA.pressed: scene.s.vel.x -= Acc * elapsed
  if ScancodeRight.pressed or ScancodeD.pressed: scene.s.vel.x += Acc * elapsed
  # Mouse
  if Button.left.pressed:
    var vector: Coord
    vector = (mouse.abs - scene.s.pos) * elapsed
    scene.s.vel += vector

