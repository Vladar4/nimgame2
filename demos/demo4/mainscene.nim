import
  math,
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  dwarf


type
  MainScene = ref object of Scene
    dG: TextureGraphic
    d: Dwarf


const Framerate = 1/12


proc init*(scene: MainScene) =
  Scene(scene).init()
  # Dwarf
  scene.dG = newTextureGraphic()
  discard scene.dG.load("../assets/gfx/dwarf.png")
  scene.d = newDwarf()
  scene.d.pos = (200, 100)
  scene.d.graphic = scene.dG
  scene.d.initSprite((24, 48))
  discard scene.d.addAnimation(
    "down", [0, 1, 2, 3, 4, 5], Framerate)
  discard scene.d.addAnimation(
    "up", [6, 7, 8, 9, 10, 11], Framerate)
  discard scene.d.addAnimation(
    "left", [12, 13, 14, 15, 16, 17], Framerate)
  discard scene.d.addAnimation(
    "right", [12, 13, 14, 15, 16, 17], Framerate, Flip.horizontal)
  scene.d.physics = new Physics
  scene.list.add(scene.d)


proc free*(scene: MainScene) =
  scene.dG.free


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


const Speed = 50


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)

  # Controls and speed
  type Direction = enum none, down, up, left, right
  var direction =
    if ScancodeDown.pressed or ScancodeS.pressed: down
    elif ScancodeUp.pressed or ScancodeW.pressed: up
    elif ScancodeLeft.pressed or ScancodeA.pressed: left
    elif ScancodeRight.pressed or ScancodeD.pressed: right
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

