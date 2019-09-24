import
  nimgame2/nimgame,
  mainscene

game = newGame()
if game.init(w = 1280, h = 720, title = "Nimgame 2: Demo 11 (Tweens)"):
  #showInfo = true
  game.scene = newMainScene()
  game.run()

