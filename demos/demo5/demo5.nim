import
  nimgame2/nimgame,
  nimgame2/settings,
  mainscene

game = new Game
if game.init(w = 640, h = 480, title = "Nimgame 2: Demo 5 (Collisions)",
             scaleQuality = 0):
  showInfo = true
  colliderOutline = true
  game.scene = newMainScene()
  game.run()

