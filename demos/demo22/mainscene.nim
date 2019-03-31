import
  random, strutils,
  nimgame2/plugin/mpeggraphic,
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  nimgame2/utils


type
  MainScene = ref object of Scene
    movie: MpegGraphic
    e: Entity


proc moviePhysics*(entity: Entity, elapsed: float) =
  defaultPhysics(entity, elapsed)

  # Screen collision
  if entity.pos.x < 0:
    entity.vel.x *= -1
  if entity.pos.y < 0:
    entity.vel.y *= -1
  if entity.pos.x >= game.size.w.float:
    entity.vel.x *= -1
  if entity.pos.y >= game.size.h.float:
    entity.vel.y *= -1


proc initMainScene*(scene: MainScene) =
  scene.initScene()
  # Movie
  scene.movie = newMpegGraphic("video.mpg")
  scene.movie.loop = true
  scene.e = newEntity()
  scene.e.graphic = scene.movie
  scene.e.physics = moviePhysics
  scene.e.pos.x = rand(game.size.w).float
  scene.e.pos.y = rand(game.size.h).float
  scene.e.vel.x = rand(10.0..100.0) * randSign().float
  scene.e.vel.y = rand(10.0..100.0) * randSign().float
  scene.e.centrify()
  scene.e.rotVel = rand(10.0..60.0) * randSign().float

  # add to scene
  scene.add(scene.e)


proc free*(scene: MainScene) =
  scene.movie.free()


proc newMainScene*(): MainScene =
  new result, free
  result.initMainScene()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()
  discard box((4, 60), (220, 124), 0x000000CC'u32)
  discard string(
    (8, 64), "Enter - play", 0xFF0000FF'u32)
  discard string(
    (8, 72), "Space - pause", 0xFF0000FF'u32)
  discard string(
    (8, 80), "Backspace - stop", 0xFF0000FF'u32)
  discard string(
    (8, 88), "R - Rewind", 0xFF0000FF'u32)
  discard string(
    (8, 96), "Up/Down - volume: " & $scene.movie.volume, 0xFF0000FF'u32)
  discard string(
    (8, 104), "Right - skip 5s", 0xFF0000FF'u32)
  discard string(
    (8, 112), "Time: " & scene.movie.currentTime.formatFloat(precision = 3) &
    "s of " & scene.movie.totalTime.formatFloat(precision = 3) & "s", 0xFF0000FF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  if ScancodeReturn.pressed: scene.movie.play()
  if ScancodeSpace.pressed: scene.movie.pause()
  if ScancodeBackspace.pressed: scene.movie.stop()
  if ScancodeR.pressed: scene.movie.rewind()
  if ScancodeUp.pressed: scene.movie.volume =
    (scene.movie.volume + 10).clamp(0, 100)
  if ScancodeDown.pressed: scene.movie.volume =
    (scene.movie.volume - 10).clamp(0, 100)
  if ScancodeRight.pressed: scene.movie.skip(5.0)

