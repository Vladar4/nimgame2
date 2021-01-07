import
  sdl2/sdl,
  nimgame2/nimgame,
  nimgame2/settings,
  mainscene

game = newGame()
if game.init(w = 640, h = 480, title = "Nimgame 2: Demo 24 (Outline)",
             scaleQuality = 0):
  showInfo = true
  game.windowSize = (1280, 960)
  game.scene = newMainScene()
  game.run()

