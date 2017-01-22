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
                procedure: proc(start, distance: Coord,
                                elapsed, duration: float): Coord) =
  # Name
  let n = newTextGraphic()
  n.font = scene.font
  n.lines = [name]
  let ne = newEntity()
  ne.graphic = n
  ne.pos = pos - (96.0, 8.0)
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
  t.setup(e.pos, e.pos + (200.0, 0.0), 1.5, -1)
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

  scene.addEntity("linear", (100.0, 100.0), linear)
  scene.addEntity("inQuad", (100.0, 150.0), inQuad)
  scene.addEntity("outQuad", (100.0, 200.0), outQuad)
  scene.addEntity("inOutQuad", (100.0, 250.0), inOutQuad)
  scene.addEntity("inCubic", (100.0, 300.0), inCubic)
  scene.addEntity("outCubic", (100.0, 350.0), outCubic)
  scene.addEntity("inOutCubic", (100.0, 400.0), inOutCubic)
  scene.addEntity("outInCubic", (100.0, 450.0), outInCubic)



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

