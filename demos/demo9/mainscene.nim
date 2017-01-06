import sdl2/sdl,
  math,
  nimgame2/audio,
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  nimgame2/utils


type
  MainScene = ref object of Scene
    tack: Sound


proc init*(scene: MainScene) =
  Scene(scene).init()

  # Sound
  scene.tack = newSound("../assets/sfx/tack.wav")
  scene.tack.volume = Volume.high div 2


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
    of K_Space:
      discard scene.tack.play()
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()

  discard box((4, 60), (260, 92), 0x000000CC'u32)

  discard string((8, 64), "Space - play sound", 0xFFFFFFFF'u32)
  discard string((8, 72),
    "Up/Down - sound volume: " & $scene.tack.volume, 0xFFFFFFFF'u32)
  discard string((8, 80), "", 0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if ScancodeUp.down: scene.tack.volumeInc(1)
  if ScancodeDown.down: scene.tack.volumeDec(1)

