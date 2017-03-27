import
  nimgame2/nimgame,
  nimgame2/settings,
  mainscene

game = newGame()
if game.init(w = 320, h = 240, title = "Nimgame 2: Demo 18 (IndexedImage)"):
  game.windowSize = (640, 480)
  showInfo = true
  game.scene = newMainScene()
  game.run()

