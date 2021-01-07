import sdl2/sdl,
  sdl2/sdl_image,
  math,
  nimgame2/nimgame,
  nimgame2/font,
  nimgame2/bitmapfont,
  nimgame2/truetypefont,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/graphic,
  #nimgame2/graphicgroup,
  nimgame2/textgraphic,
  nimgame2/surfacegraphic,
  nimgame2/texturegraphic,
  nimgame2/typewriter,
  nimgame2/input,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  nimgame2/utils,
  nimgame2/outline,
  earth


type
  MainScene = ref object of Scene
    earthG: TextureGraphic
    e: Earth
    bmFont: BitmapFont
    ttFont: TrueTypeFont

    cleanText, outlinedText, shadowedText: TextGraphic
    textOutline, textShadow: Outline
    cleanTextEntity, outlinedTextEntity, textOutlineEntity,
      textShadowEntity, shadowedTextEntity: Entity

    twText: TextGraphic
    twEntity: Typewriter
    twOutline: Outline
    twOutlineEntity: Entity


proc initMainScene*(scene: MainScene) =
  scene.initScene()

  # Earth
  scene.e = newEarth()
  scene.e.layer = -100
  scene.earthG = newTextureGraphic()
  discard scene.earthG.load("../assets/gfx/earth.png")
  scene.e.graphic = scene.earthG

  # BitmapFont
  scene.bmFont = newBitmapFont()
  discard scene.bmFont.load("../assets/fnt/default8x16.png", (8, 16))

  # TrueTypeFont
  scene.ttFont = newTrueTypeFont()
  discard scene.ttFont.load("../assets/fnt/FSEX300.ttf", 16)

  # Text without outline
  scene.cleanText = newTextGraphic()
  scene.cleanText.font = scene.bmFont
  scene.cleanText.lines =
    [ "Multi-line text",
      "without outline"]
  scene.cleanTextEntity = newEntity()
  scene.cleanTextEntity.pos = (72, 96)
  scene.cleanTextEntity.graphic = scene.cleanText

  # Text with outline
  scene.outlinedText = newTextGraphic()
  scene.outlinedText.font = scene.bmFont
  scene.outlinedText.lines =
    [ "Multi-line text",
      "with outline"]
  scene.outlinedTextEntity = newEntity()
  scene.outlinedTextEntity.pos = (72, 160)
  scene.outlinedTextEntity.graphic = scene.outlinedText
  scene.textOutline = newOutline(color = ColorBlack)
  discard scene.textOutline.updateOutline(scene.outlinedText.surface)
  scene.textOutlineEntity = newEntity()
  scene.textOutlineEntity.graphic = scene.textOutline
  scene.textOutlineEntity.parent = scene.outlinedTextEntity
  scene.textOutlineEntity.pos = (-scene.textOutline.thickness,
                                     -scene.textOutline.thickness)


  # Text with shadow
  scene.shadowedText = newTextGraphic()
  scene.shadowedText.font = scene.bmFont
  scene.shadowedText.lines =
    [ "Multi-line text",
      "with shadow"]
  scene.shadowedTextEntity = newEntity()
  scene.shadowedTextEntity.pos = (72, 224)
  scene.shadowedTextEntity.graphic = scene.shadowedText
  scene.textShadow = newOutline(color = ColorBlack,
                                thickness = 2,
                                shadow = true)
  discard scene.textShadow.updateOutline(scene.shadowedText.surface)
  scene.textShadowEntity = newEntity()
  scene.textShadowEntity.graphic = scene.textShadow
  scene.textShadowEntity.parent = scene.shadowedTextEntity
  scene.textShadowEntity.pos = (-scene.textShadow.thickness / 2,
                                -scene.textShadow.thickness / 2)
  scene.textShadowEntity.layer = scene.textShadowEntity.parent.layer - 1

  # Typewriter (TTF) with outline
  scene.twText = newTextGraphic()
  scene.twText.font = scene.ttFont
  scene.twEntity = newTypewriter(scene.twText, 0.1)
  #scene.twEntity.width = 10 # uncomment to enable text wrapping
  scene.twEntity.pos = (300, 8)
  scene.twEntity.add "Typewriter effect"
  scene.twEntity.add "with outline!"
  scene.twOutline = newOutline(color = ColorRed)
  # outline will be updated in the updateOutline proc below
  scene.twOutlineEntity = newEntity()
  scene.twOutlineEntity.graphic = scene.twOutline
  scene.twOutlineEntity.parent = scene.twEntity
  scene.twOutlineEntity.pos = (-scene.twOutline.thickness,
                               -scene.twOutline.thickness)

  # add to scene
  scene.add(scene.cleanTextEntity)
  scene.add(scene.outlinedTextEntity)
  scene.add(scene.textOutlineEntity)
  scene.add(scene.shadowedTextEntity)
  scene.add(scene.textShadowEntity)
  scene.add(scene.twEntity)
  scene.add(scene.twOutlineEntity)
  scene.add(scene.e)


proc free*(scene: MainScene) =
  scene.bmFont.free()
  scene.ttFont.free()
  scene.cleanText.free()
  scene.outlinedText.free()
  scene.textOutline.free()
  scene.shadowedText.free()
  scene.textShadow.free()
  scene.twOutline.free()


proc newMainScene*(): MainScene =
  new result, free
  result.initMainScene()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    of K_Return:
      scene.twEntity.force()
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()


proc updateOutline(scene: MainScene) =
  let
    outline = Outline(scene.twOutline)
    source = scene.twText.surface
  discard outline.updateOutline(source)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)
  scene.updateOutline()
  if ScancodeReturn.down: scene.twEntity.force()

