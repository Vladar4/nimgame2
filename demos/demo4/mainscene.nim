import
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  dwarf


type
  MainScene = ref object of Scene
    d: Dwarf


proc initMainScene*(scene: MainScene) =
  scene.initScene()
  scene.d = newDwarf()
  scene.d.pos = (200, 200)
  scene.add(scene.d)


proc newMainScene*(): MainScene =
  new result
  result.initMainScene()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
      case event.key.keysym.sym:
      of K_Escape:
        gameRunning = false
      else: discard


method render*(scene: MainScene) =
  scene.renderScene()


const Speed = 50


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)

  # Controls and speed
  type Direction = enum none, down, up, left, right
  var direction =
    if ScancodeDown.down or ScancodeS.down: down
    elif ScancodeUp.down or ScancodeW.down: up
    elif ScancodeLeft.down or ScancodeA.down: left
    elif ScancodeRight.down or ScancodeD.down: right
    else: none

  case direction:
  of none:
    if not scene.d.sprite.playing:
      scene.d.vel = (0, 0)
  of down:
    if  not scene.d.sprite.playing or
        (scene.d.currentAnimationName != "down"):
      scene.d.play("down", 1)
      scene.d.vel = (0, Speed)
  of up:
    if  not scene.d.sprite.playing or
        (scene.d.currentAnimationName != "up"):
      scene.d.play("up", 1)
      scene.d.vel = (0, -Speed)
  of left:
    if  not scene.d.sprite.playing or
        (scene.d.currentAnimationName != "left"):
      scene.d.play("left", 1)
      scene.d.vel = (-Speed, 0)
  of right:
    if  not scene.d.sprite.playing or
        (scene.d.currentAnimationName != "right"):
      scene.d.play("right", 1)
      scene.d.vel = (Speed, 0)

