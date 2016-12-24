import
  nimgame2/nimgame,
  mainscene

game = new Game
if game.init(w = 640, h = 480, title = "Nimgame 2: Demo 4 (Sprite & Animation)"):
  game.showInfo = true
  game.scene = newMainScene()
  game.run()

