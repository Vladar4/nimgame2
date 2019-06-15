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
    ePoint, eLine, eCircle, eBox, eScaled: Emitter


proc init*(scene: MainScene) =
  Scene(scene).init()
  # Particle Graphic
  scene.particleG = newTextureGraphic()
  discard scene.particleG.load("../assets/gfx/puff.png")

  # Particle
  var particle: Particle
  particle = newParticle()
  particle.graphic = scene.particleG
  particle.initSprite((5, 5))
  particle.centrify()
  discard particle.addAnimation("play", toSeq(0..4), 1/5)
  particle.play("play", 1, kill = true)

  # Point emitter
  scene.ePoint = newEmitter(scene)
  scene.ePoint.randomVel = (10.0, 10.0)
  scene.ePoint.randomAcc = (5.0, 5.0)
  scene.ePoint.randomTTL = 5.0
  scene.ePoint.particle = particle
  scene.add(scene.ePoint)

  # Line emitter
  scene.eLine = newEmitter(scene, eaLine)
  scene.eLine.area.length = 100.0
  scene.eLine.randomVel = (10.0, 10.0)
  scene.eLine.randomAcc = (5.0, 5.0)
  scene.eLine.randomTTL = 5.0
  scene.eLine.particle = particle
  scene.eLine.pos = game.size / 2
  scene.add(scene.eLine)

  # Circle emitter
  scene.eCircle = newEmitter(scene, eaCircle)
  scene.eCircle.area.radius = 100.0
  scene.eCircle.randomVel = (10.0, 10.0)
  scene.eCircle.randomAcc = (5.0, 5.0)
  scene.eCircle.randomTTL = 5.0
  scene.eCircle.particle = particle
  scene.eCircle.pos = game.size / 4
  scene.add(scene.eCircle)

  # Box emitter
  scene.eBox = newEmitter(scene, eaBox)
  scene.eBox.area.dim = (100.0, 50.0)
  scene.eBox.rotVel = -90.0
  scene.eBox.randomVel = (10.0, 10.0)
  scene.eBox.randomAcc = (5.0, 5.0)
  scene.eBox.randomTTL = 5.0
  scene.eBox.particle = particle
  scene.eBox.pos = game.size / 2 + game.size / 4
  scene.add(scene.eBox)

  # Scaling particles
  var particleScaled: Particle
  particleScaled = newParticle()
  particleScaled.graphic = scene.particleG
  particleScaled.initSprite((5, 5))
  particleScaled.centrify()
  discard particleScaled.addAnimation("play", toSeq(0..4), 1/2)
  particleScaled.play("play", 1, kill = true)
  particleScaled.scale = 0.5
  particleScaled.scaleVel = 1.0

  scene.eScaled = newEmitter(scene)
  scene.eScaled.randomVel = (50.0, 50.0)
  scene.eScaled.randomAcc = (5.0, 5.0)
  scene.eScaled.randomTTL = 5.0
  scene.eScaled.particle = particleScaled
  scene.eScaled.pos = (game.size.w div 2 + game.size.w div 4, game.size.h div 4)
  scene.add(scene.eScaled)



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
  # Point emitter
  scene.ePoint.pos = mouse.abs
  if MouseButton.left.down:
    scene.ePoint.emit(5)
  # Line emitter
  scene.eLine.rot += 90 * elapsed
  scene.eLine.emit(5)
  # Circle emitter
  scene.eCircle.area.radius = if MouseButton.left.down: 50.0 else: 100.0
  scene.eCircle.emit(scene.eCircle.area.radius.int div 20)
  # Box emitter
  scene.eBox.rot += scene.eBox.rotVel * elapsed
  scene.eBox.emit(5)
  # Scaled emitter
  scene.eScaled.emit(5)

