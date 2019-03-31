import sdl2/sdl,
  math,
  nimgame2/assets,
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


var
  musicData: Assets[Music]


proc initMainScene*(scene: MainScene) =
  scene.initScene()

  # Sound
  scene.tack = newSound("../assets/sfx/tack.wav")
  scene.tack.volume = Volume.high div 2

  # Music
  musicData = newAssets[Music]("../assets/mus",
    proc(file: string): Music = newMusic(file))
  playlist = newPlaylist()
  for track in musicData.values:
    playlist.list.add(track)


proc free*(scene: MainScene) =
  discard


proc newMainScene*(): MainScene =
  new result, free
  result.initMainScene()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    of K_Space:
      discard scene.tack.play()
    of K_M:
      discard playlist.play()
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()

  discard box((4, 60), (260, 92), 0x000000CC'u32)

  discard string((8, 64), "Space - play sound", 0xFFFFFFFF'u32)
  discard string((8, 72),
    "Up/Down - sound volume: " & $scene.tack.volume, 0xFFFFFFFF'u32)
  discard string((8, 80), "M - play random music track", 0xFFFFFFFF'u32)
  discard string((8, 88),
    "PgUp/PgDn - music volume: " & $getMusicVolume(), 0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if ScancodeUp.down: scene.tack.volumeInc(1)
  if ScancodeDown.down: scene.tack.volumeDec(1)
  if ScancodePageUp.down: musicVolumeInc(1)
  if ScancodePageDown.down: musicVolumeDec(1)

