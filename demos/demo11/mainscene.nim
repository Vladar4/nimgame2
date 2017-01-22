import
  nimgame2/nimgame,
  nimgame2/bitmapfont,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/textgraphic,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/tween,
  nimgame2/types,
  earth


type
  MainScene = ref object of Scene
    earthG: TextureGraphic
    font: BitmapFont
    tweens: seq[Tween[Entity,Coord]]


proc addEntity*(scene: MainScene,
                name: string,
                pos: Coord,
                procedure: TweenProcedure[Coord]) =
  # Name
  let n = newTextGraphic()
  n.font = scene.font
  n.lines = [name]
  let ne = newEntity()
  ne.graphic = n
  ne.pos = pos - (98.0, 8.0)
  scene.add(ne)

  # Entity
  let e = newEarth(pos)
  e.graphic = scene.earthG
  e.centrify()
  scene.add(e)

  # Tween
  let t = newTween[Entity,Coord](
    e,
    proc(t: Entity): Coord = t.pos,
    proc(t: Entity, val: Coord) = t.pos = val)
  t.procedure = procedure
  scene.tweens.add(t)
  t.setup(e.pos, e.pos + (150.0, 0.0), 3.0, -1)
  t.play()


proc init*(scene: MainScene) =
  Scene(scene).init()
  scene.tweens = @[]

  # Earth graphic
  scene.earthG = newTextureGraphic()
  discard scene.earthG.load("../assets/gfx/earth32.png")

  # Font
  scene.font = newBitmapFont()
  discard scene.font.load("../assets/fnt/default8x16.png", (8, 16))

  # Column 1
  scene.addEntity("linear", (100.0, 35.0), linear)
  scene.addEntity("inQuad", (100.0, 85.0), inQuad)
  scene.addEntity("outQuad", (100.0, 135.0), outQuad)
  scene.addEntity("inOutQuad", (100.0, 185.0), inOutQuad)

  scene.addEntity("inCubic", (100.0, 285.0), inCubic)
  scene.addEntity("outCubic", (100.0, 335.0), outCubic)
  scene.addEntity("inOutCubic", (100.0, 385.0), inOutCubic)
  scene.addEntity("outInCubic", (100.0, 435.0), outInCubic)

  scene.addEntity("inQuart", (100.0, 535.0), inQuart)
  scene.addEntity("outQuart", (100.0, 585.0), outQuart)
  scene.addEntity("inOutQuart", (100.0, 635.0), inOutQuart)
  scene.addEntity("outInQuart", (100.0, 685.0), outInQuart)

  # Column 2
  scene.addEntity("inQuint", (400.0, 35.0), inQuint)
  scene.addEntity("outQuint", (400.0, 85.0), outQuint)
  scene.addEntity("inOutQuint", (400.0, 135.0), inOutQuint)
  scene.addEntity("outInQuint", (400.0, 185.0), outInQuint)

  scene.addEntity("inSine", (400.0, 285.0), inSine)
  scene.addEntity("outSine", (400.0, 335.0), outSine)
  scene.addEntity("inOutSine", (400.0, 385.0), inOutSine)
  scene.addEntity("outInSine", (400.0, 435.0), outInSine)

  # Column 3
  scene.addEntity("inExpo", (700.0, 35.0), inExpo)
  scene.addEntity("outExpo", (700.0, 85.0), outExpo)
  scene.addEntity("inOutExpo", (700.0, 135.0), inOutExpo)
  scene.addEntity("outInExpo", (700.0, 185.0), outInExpo)

  scene.addEntity("inCirc", (700.0, 285.0), inCirc)
  scene.addEntity("outCirc", (700.0, 335.0), outCirc)
  scene.addEntity("inOutCirc", (700.0, 385.0), inOutCirc)
  scene.addEntity("outInCirc", (700.0, 435.0), outInCirc)

  # Column 4
  scene.addEntity("inBounce", (1000.0, 35.0), inBounce)
  scene.addEntity("outBounce", (1000.0, 85.0), outBounce)
  scene.addEntity("inOutBounce", (1000.0, 135.0), inOutBounce)
  scene.addEntity("outInBounce", (1000.0, 185.0), outInBounce)

  #scene.addEntity("inElastic", (1000.0, 285.0), inElastic)
  #scene.addEntity("outElastic", (1000.0, 335.0), outElastic)
  #scene.addEntity("inOutElastic", (1000.0, 385.0), inOutElastic)
  #scene.addEntity("outInElastic", (1000.0, 435.0), outInElastic)

  #scene.addEntity("inBack", (1000.0, 535.0), inBack)
  #scene.addEntity("outBack", (1000.0, 585.0), outBack)
  #scene.addEntity("inOutBack", (1000.0, 635.0), inOutBack)
  #scene.addEntity("outInBack", (1000.0, 685.0), outInBack)


proc free*(scene: MainScene) =
  scene.earthG.free


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


method update*(scene: MainScene, elapsed: float) =
  for tween in scene.tweens:
    tween.update(elapsed)
  scene.updateScene(elapsed)

