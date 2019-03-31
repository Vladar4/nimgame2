import
  nimgame2/graphic,
  nimgame2/input,
  nimgame2/gui/button


type
  SquareButton* = ref object of GuiButton


proc initSquareButton*(btn: SquareButton, graphic: Graphic, image: Graphic = nil) =
  btn.initGuiButton(graphic, image)


proc newSquareButton*(graphic: Graphic, image: Graphic = nil): SquareButton =
  new result
  result.initSquareButton(graphic, image)


method onClick*(btn: SquareButton, mb: MouseButton) =
  echo "clicked square button"

