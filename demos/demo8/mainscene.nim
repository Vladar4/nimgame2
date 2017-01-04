import sdl2/sdl,
  math,
  nimgame2/nimgame,
  nimgame2/collider,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/graphic,
  nimgame2/input,
  nimgame2/procgraphic,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  nimgame2/utils


type
  MainScene = ref object of Scene
    polyG: ProcGraphic
    poly: Entity


const polyLines0 = [
  (  0.0, -70.0),
  ( 40.0, -30.0),
  ( 80.0, -50.0),
  ( 60.0,  30.0),
  (-60.0,  30.0),
  (-80.0, -50.0),
  (-40.0, -30.0),
  (  0.0, -70.0)]

const polyLines1 = [
  ((-30.0,  10.0), (-30.0, -10.0)),
  ((-30.0, -10.0), (-10.0,  10.0)),
  ((-10.0,  10.0), (-10.0, -10.0)),
  ((  0.0, -10.0), (  0.0,  10.0)),
  (( 10.0,  10.0), ( 10.0, -10.0)),
  (( 10.0, -10.0), ( 20.0,   0.0)),
  (( 20.0,   0.0), ( 30.0, -10.0)),
  (( 30.0, -10.0), ( 30.0,  10.0))]


proc polyProc(pos: Coord,
              angle: Angle,
              scale: Scale,
              center: Coord,
              flip: Flip,
              region: Rect) =
  let
    color0: Color = 0xFFFF00FF'u32
    color1: Color = 0xFFFFFFFF'u32

  for i in 1..(polyLines0.high):
    let
      p0 = rotate(polyLines0[i - 1], (0.0, 0.0), angle) * scale + pos
      p1 = rotate(polyLines0[i], (0.0, 0.0), angle) * scale + pos
    discard line(p0, p1, color0)

  for i in polyLines1:
    let
      p0 = rotate(i[0], (0.0, 0.0), angle) * scale + pos
      p1 = rotate(i[1], (0.0, 0.0), angle) * scale + pos
    discard line(p0, p1, color1)


proc init*(scene: MainScene) =
  Scene(scene).init()

  # Poly
  scene.poly = newEntity()
  scene.polyG = newProcGraphic()
  scene.polyG.procedure = polyProc
  scene.poly.graphic = scene.polyG
  scene.poly.pos = (320, 240)

  # add to scene
  scene.list.add(scene.poly)


proc free*(scene: MainScene) =
  discard


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
  scene.renderScene()

  discard box((4, 60), (260, 92), 0x000000CC'u32)

  discard string((8, 64), "WSAD - move", 0xFFFFFFFF'u32)
  discard string((8, 72), "QE   - rotate", 0xFFFFFFFF'u32)
  discard string((8, 80), "RF   - scale", 0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if ScancodeA.pressed: scene.poly.pos.x -= 1
  if ScancodeD.pressed: scene.poly.pos.x += 1
  if ScancodeW.pressed: scene.poly.pos.y -= 1
  if ScancodeS.pressed: scene.poly.pos.y += 1
  if ScancodeQ.pressed: scene.poly.rot -= 1
  if ScancodeE.pressed: scene.poly.rot += 1
  if ScancodeR.pressed: scene.poly.scale -= 0.01
  if ScancodeF.pressed: scene.poly.scale += 0.01

