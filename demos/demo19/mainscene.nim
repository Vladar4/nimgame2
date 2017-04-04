import
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/perspectiveimage,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types


const
  GraphicCount = 17
  Positions: array[GraphicCount, Coord] = [
    (125.0, 125.0), (275, 125), (375, 125), (475, 125), (575, 125),
    (75, 275), (175, 275), (275, 275), (375, 275), (475, 275), (575, 275),
    (75, 425), (175, 425), (275, 425), (375, 425), (475, 400), (575, 425),
  ]


type
  MainScene = ref object of Scene
    pimg: PerspectiveImage
    graphics: array[GraphicCount, TextureGraphic]
    entities: array[GraphicCount, Entity]


proc init*(scene: MainScene) =
  Scene(scene).init()

  scene.pimg = newPerspectiveImage("../assets/gfx/grid.png")

  # graphics
  for i in 0..scene.graphics.high:
    scene.graphics[i] = newTextureGraphic()

  discard scene.graphics[0].assignTexture(scene.pimg.render(
    pdHor, 0, 0))
  discard scene.graphics[1].assignTexture(scene.pimg.render(
    pdHor, 96, 32))
  discard scene.graphics[2].assignTexture(scene.pimg.render(
    pdHor, 32, 96))
  discard scene.graphics[3].assignTexture(scene.pimg.render(
    pdHor, 64, 32, 32))
  discard scene.graphics[4].assignTexture(scene.pimg.render(
    pdHor, 32, 64, 32))
  discard scene.graphics[5].assignTexture(scene.pimg.render(
    pdVer, 96, 32))
  discard scene.graphics[6].assignTexture(scene.pimg.render(
    pdVer, 64, 32, 32))
  discard scene.graphics[7].assignTexture(scene.pimg.render(
    pdHor, 64, 32, shift = 0.0))
  discard scene.graphics[8].assignTexture(scene.pimg.render(
    pdHor, 32, 64, shift = 1.0))
  discard scene.graphics[9].assignTexture(scene.pimg.render(
    pdHor, 64, 32, shift = 0.25))
  discard scene.graphics[10].assignTexture(scene.pimg.render(
    pdHor, 32, 64, shift = 0.75))
  discard scene.graphics[11].assignTexture(scene.pimg.render(
    pdVer, 32, 96))
  discard scene.graphics[12].assignTexture(scene.pimg.render(
    pdVer, 32, 64, 32))
  discard scene.graphics[13].assignTexture(scene.pimg.render(
    pdVer, 64, 32, shift = 0.0))
  discard scene.graphics[14].assignTexture(scene.pimg.render(
    pdVer, 64, 32, shift = 1.0))
  discard scene.graphics[15].assignTexture(scene.pimg.render(
    pdVer, 64, 32, shift = 0.25))
  discard scene.graphics[16].assignTexture(scene.pimg.render(
    pdVer, 32, 64, shift = 0.75))

  # entities
  for i in 0..scene.entities.high:
    scene.entities[i] = newEntity()
    scene.entities[i].graphic = scene.graphics[i]
    scene.entities[i].centrify()
    scene.entities[i].pos = Positions[i]

  # add to scene
  for entity in scene.entities:
    scene.add(entity)


proc free*(scene: MainScene) =
  scene.pimg.free()
  for graphic in scene.graphics:
    graphic.free()


proc newMainScene*(): MainScene =
  new result, free
  result.init()


method event*(scene: MainScene, event: Event) =
  scene.eventScene(event)
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()

