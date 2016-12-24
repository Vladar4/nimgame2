import
  nimgame2/nimgame,
  mainscene

game = new Game
if game.init(w = 640, h = 480, title = "Nimgame 2: Demo 2 (Graphic)",
             scaleQuality = 0):
  game.showInfo = true
  game.scene = newMainScene()
  game.run()

