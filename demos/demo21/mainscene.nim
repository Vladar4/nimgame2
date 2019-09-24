import
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  joypoint


type
  MainScene = ref object of Scene
    joypoints: seq[JoyPoint]


proc initMainScene*(scene: MainScene) =
  scene.initScene()
  scene.joypoints = @[]
  for i in 0..<numJoysticks():
    discard openJoystick(i)
    scene.joypoints.add(newJoyPoint(i))
    scene.add(scene.joypoints[^1])


proc free*(scene: MainScene) =
  discard

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


proc joyInfo(id: int): string =
  result = joyName(id)
  for i in 0..<joyNumButtons(id):
    if joyDown(id, i):
      result &= " " & $i


method render*(scene: MainScene) =
  scene.renderScene()
  discard box((4, 60), (260, 84), 0x000000CC'u32)
  var y = 64
  for i in 0..<numJoysticks():
    discard string(
      (8, y), joyInfo(i), 0xFFFFFFFF'u32)
    y += 8


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)

