import sdl2/sdl,
  math,
  nimgame2/nimgame,
  nimgame2/collider,
  nimgame2/font,
  nimgame2/bitmapfont,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/graphic,
  nimgame2/textgraphic,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  earth


type
  MainScene = ref object of Scene
    earthG: TextureGraphic
    e: Earth
    bmFont: BitmapFont
    bmText: TextGraphic
    bmEntity: Entity


proc init*(scene: MainScene) =
  Scene(scene).init()

  # Earth
  scene.e = newEarth()
  scene.earthG = newTextureGraphic()
  discard scene.earthG.load("../assets/gfx/earth.png")
  scene.e.graphic = scene.earthG

  # BitmapFont
  scene.bmFont = newBitmapFont()
  discard scene.bmFont.load("../assets/fnt/default8x16.png", (8, 16))

  # Text
  scene.bmText = newTextGraphic()
  scene.bmText.font = scene.bmFont
  scene.bmText.lines =
    [ "The quick brown fox",
      "jumps over the lazy dog"]

  scene.bmEntity = newEntity()
  scene.bmEntity.pos = (8, 128)
  scene.bmEntity.graphic = scene.bmText

  # add to scene
  scene.list.add(scene.e)
  scene.list.add(scene.bmEntity)


proc free*(scene: MainScene) =
  scene.bmFont.free


proc newMainScene*(): MainScene =
  new result, free
  result.init()


proc bmChangeAlign(scene: MainScene, increase = true) =
  # get
  var a = scene.bmText.align
  # change
  if increase:
    if a.int == 0:
      a = TextAlign(1)
    elif a < TextAlign.high:
      a = TextAlign(a.int shl 1)
  else: # decrease
    if a.int > 0:
      a = TextAlign(a.int shr 1)
  # set
  scene.bmText.align = a

let
  colors = [0xFFFFFFFF'u32, 0xFF0000FF'u32, 0x00FF00FF'u32, 0x0000FFFF'u32]
  colorNames = ["white", "red", "green", "blue"]
var bmColor = 0

proc bmChangeColor(scene: MainScene, increase = true) =
  # change
  if increase:
    if bmColor < colors.high:
      inc bmColor
  else: # decrease
    if bmColor > 0:
      dec bmColor
  # set
  scene.bmText.color = colors[bmColor]


proc bmChangeAlpha(scene: MainScene, increase = true) =
  # get
  var
    c = scene.bmText.color
    a = c.a.int
  # change
  if increase:
    a += 15
  else: # decrease
    a -= 15
  # check limits
  if a < 0:
    a = 0
  if a > 255:
    a = 255
  # set
  c.a = a.uint8
  scene.bmText.color = c


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    of K_Q:
      scene.bmChangeAlign()
    of K_A:
      scene.bmChangeAlign(false)
    of K_W:
      scene.bmChangeColor()
    of K_S:
      scene.bmChangeColor(false)
    of K_E:
      scene.bmChangeAlpha()
    of K_D:
      scene.bmChangeAlpha(false)
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()

  discard box((4, 60), (260, 100), 0x000000CC'u32)

  discard string((8, 64), "BitmapFont:", 0xFFFFFFFF'u32)
  discard string((8, 72),
    "QA - change alignment: " & $scene.bmText.align, 0xFFFFFFFF'u32)
  discard string((8, 80),
    "WS - change color: " & colorNames[bmColor], 0xFFFFFFFF'u32)
  discard string((8, 88),
    "ED - change alpha: " & $scene.bmText.color.a.int, 0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)

