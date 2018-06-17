import
  nimgame2 / [
    nimgame, settings
  ],
  mainscene


game = newGame()
settings.updateInterval = 1000
if game.init(400, 400, "TextEntity module test"):
  game.scene = newMainScene()
  settings.showInfo = true
  game.run()