import
  nimgame2/graphic,
  nimgame2/input,
  nimgame2/gui/widget,
  nimgame2/gui/button


type
  SquareButton* = ref object of GuiButton


proc initSquareButton*(btn: SquareButton, graphic: Graphic, image: Graphic = nil) =
  btn.initGuiButton(graphic, image)


proc newSquareButton*(graphic: Graphic, image: Graphic = nil): SquareButton =
  new result
  result.initSquareButton(graphic, image)


proc clickSquareButton*(btn: SquareButton, mb: MouseButton) =
  btn.clickGuiButton(mb)
  echo "clicked square button"


method click*(btn: SquareButton, mb: MouseButton) =
  btn.clickSquareButton(mb)

