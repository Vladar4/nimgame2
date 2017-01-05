import
  sdl2/sdl,
  nimgame2/nimgame,
  nimgame2/settings,
  mainscene

game = newGame()
if game.init(w = 640, h = 480, title = "Nimgame 2: Demo 6 (Text)",
             scaleQuality = 0):
  showInfo = true
  game.scene = newMainScene()
  game.run()

