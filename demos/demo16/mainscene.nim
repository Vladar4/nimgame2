import
  nimgame2/nimgame,
  nimgame2/draw,
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/input,
  nimgame2/mosaic,
  nimgame2/scene,
  nimgame2/settings,
  nimgame2/types,
  nimgame2/gui/widget,
  btnSquare, btnCircle


type
  MainScene = ref object of Scene
    btnSquareG, btnCircleG, iconX, btnMosaicG: TextureGraphic
    btnSquare, btnMosaic: SquareButton
    btnCircle: CircleButton


proc init*(scene: MainScene) =
  Scene(scene).init()
  # Graphics
  scene.btnSquareG = newTextureGraphic()
  discard scene.btnSquareG.load("../assets/gfx/button_square.png")
  scene.btnCircleG = newTextureGraphic()
  discard scene.btnCircleG.load("../assets/gfx/button_circle.png")
  scene.iconX = newTextureGraphic()
  discard scene.iconX.load("../assets/gfx/icon_x.png")
  let mosaic = newMosaic("../assets/gfx/button_square.png", (8, 8))
  scene.btnMosaicG = newTextureGraphic()
  discard scene.btnMosaicG.assignTexture mosaic.render(
    patternRepeat(@[
      (1, 2, @[1,4,1]),
      (4, 2, @[1,4,1]),
      (1, 2, @[1,4,1]),
      (1, 2, @[1,4,1]),
      (4, 2, @[1,4,1]),
      (1, 2, @[1,4,1]),
    ])
  )


  # Square Button
  scene.btnSquare = newSquareButton(scene.btnSquareG, scene.iconX)
  scene.btnSquare.mbAllow.set(MouseButton.right)
  scene.btnSquare.pos = (100, 100)
  # Circle Button
  scene.btnCircle = newCircleButton(scene.btnCircleG)
  scene.btnCircle.pos = (150, 100)
  # Mosaic Button
  scene.btnMosaic = newSquareButton(scene.btnMosaicG)
  scene.btnMosaic.pos = (200, 100)

  # add to scene
  scene.add(scene.btnMosaic)
  scene.add(scene.btnSquare)
  scene.add(scene.btnCircle)


proc free*(scene: MainScene) =
  scene.btnSquareG.free()
  scene.btnCircleG.free()
  scene.iconX.free()


proc newMainScene*(): MainScene =
  new result, free
  result.init()


method event*(scene: MainScene, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.sym:
    of K_Escape:
      gameRunning = false
    of K_Space:
      colliderOutline = not colliderOutline
    else: discard


method render*(scene: MainScene) =
  scene.renderScene()
  discard box((4, 60), (220, 76), 0x000000CC'u32)
  discard string(
    (8, 64), "Space - toggle collider outlines", 0xFFFFFFFF'u32)


method update*(scene: MainScene, elapsed: float) =
  scene.updateScene(elapsed)

