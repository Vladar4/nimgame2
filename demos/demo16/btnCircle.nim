import
  nimgame2/graphic,
  nimgame2/input,
  nimgame2/gui/button


type
  CircleButton* = ref object of GuiButton


proc init*(btn: CircleButton, graphic: Graphic) =
  GuiButton(btn).init(graphic, circle = true)


proc newCircleButton*(graphic: Graphic): CircleButton =
  new result
  result.init(graphic)


method onClick*(btn: CircleButton, mb: MouseButton) =
  echo "clicked circle button"

