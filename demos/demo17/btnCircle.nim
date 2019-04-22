import
  nimgame2/graphic,
  nimgame2/input,
  nimgame2/gui/widget,
  nimgame2/gui/button


type
  CircleButton* = ref object of GuiButton


proc initCircleButton*(btn: CircleButton, graphic: Graphic) =
  btn.initGuiButton(graphic, circle = true)


proc newCircleButton*(graphic: Graphic): CircleButton =
  new result
  result.initCircleButton(graphic)


proc clickCircleButton*(btn: CircleButton, mb: MouseButton) =
  btn.clickGuiButton(mb)
  echo "clicked circle button, toggled " & (if btn.toggled: "on" else: "off")


method click*(btn: CircleButton, mb: MouseButton) =
  btn.clickCircleButton(mb)

