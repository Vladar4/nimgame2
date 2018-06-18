import 
  nimgame2 / [
    types, graphic,types
  ]
type
  BorderFillGraphic* = ref object of Graphic
    border_color*, fill_color*: Color
    # border_thickness*: float #NOTE can't set border thickness at the moment
    draw_border*, draw_filled*:bool
proc initBorderFillGraphic*(self:BorderFillGraphic)=
  self.draw_border = true
  self.draw_filled = true
  self.fill_color=ColorPurple ## Traditional visual debugging color
  self.border_color=ColorPink
  # self.border_thickness = 1.0
method draw*(graphic: BorderFillGraphic,
             pos: Coord = (0.0, 0.0),
             angle: Angle = 0.0,
             scale: Scale = 1.0,
             center: Coord = (0.0, 0.0),
             flip: Flip = Flip.none,
             region: Rect = Rect(x: 0, y: 0, w: 0, h: 0))=
  raise newException(SystemError, "Can't use BorderFillGraphic draw method.")
  
method dim*(graphic: BorderFillGraphic): Dim=
  raise newException(SystemError, "Can't use BorderFillGraphic dim method.")
