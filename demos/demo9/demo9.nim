import
  sdl2/sdl,
  nimgame2/nimgame,
  nimgame2/settings,
  nimgame2/assets,
  nimgame2/texturegraphic,
  mainscene

game = newGame()
if game.init(w = 640, h = 480, title = "Nimgame 2: Demo 9 (Audio)",
             scaleQuality = 0):
  showInfo = true
  game.scene = newMainScene()
  game.run()
  let ass = newAssets[TextureGraphic]("../assets/gfx", proc(file: string): TextureGraphic = newTextureGraphic(file))

