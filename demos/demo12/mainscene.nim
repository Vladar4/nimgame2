import
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/emitter,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types


type
  MainScene = ref object of Scene
    particleG: TextureGraphic
    e: Emitter


proc init*(scene: MainScene) =
  Scene(scene).init()
  # Particle Graphic
  scene.particleG = newTextureGraphic()
  discard scene.particleG.load("../assets/gfx/puff.png")
  # Emitter
  scene.e = newEmitter(scene)
  scene.add(scene.e)
  scene.e.randomVel = (10.0, 10.0)
  scene.e.randomAcc = (5.0, 5.0)
  scene.e.randomTTL = 5.0
  # Particle
  scene.e.particle = newParticle()
  scene.e.particle.graphic = scene.particleG
  scene.e.particle.initSprite((5, 5))
  scene.e.particle.centrify()
  discard scene.e.particle.addAnimation("play", toSeq(0..4), 1/5)
  scene.e.particle.play("play", 1, kill = true)


proc free*(scene: MainScene) =
  scene.particleG.free()


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
  scene.renderScene()


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  scene.e.pos = mouse.abs
  if MouseButton.left.pressed:
    scene.e.emit(5)

