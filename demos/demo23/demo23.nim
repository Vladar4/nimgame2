import
  nimgame2 / [
    nimgame, settings
  ],
  mainscene


game = newGame()
if game.init(640, 480, "Nimgame 2: Demo 22 (Transform)"):
  game.scene = newMainScene()
  settings.updateInterval = 1000
  settings.showInfo = true
  game.run()