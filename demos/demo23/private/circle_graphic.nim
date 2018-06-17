import
  nimgame2 / [
    types, graphic, draw, utils
  ],
  border_fill_graphic

type
  CircleGraphic* = ref object of BorderFillGraphic
    radius*: float
    


proc drawCircleGraphic*(self: CircleGraphic,
                      pos: Coord = (0.0, 0.0),
                      angle: Angle = 0.0,
                      scale: Scale = 1.0,
                      center: Coord = (0.0, 0.0),
                      flip: Flip = Flip.none,
                      region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  let point:Coord = pos
  if self.draw_filled:
    discard circle(point, self.radius, self.fill_color, DrawMode.filled)
  if self.draw_border:
    discard circle(point, self.radius, self.border_color, DrawMode.default)




method draw*(graphic: CircleGraphic,
             pos: Coord = (0.0, 0.0),
             angle: Angle = 0.0,
             scale: Scale = 1.0,
             center: Coord = (0.0, 0.0),
             flip: Flip = Flip.none,
             region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  drawCircleGraphic(graphic, pos, angle, scale, center, flip, region)
proc newCircleGraphic*():CircleGraphic=
  new result
  result.initBorderFillGraphic()
  result.radius = 5.0

method dim*(self:CircleGraphic):Dim=
  return (int self.radius*2,int self.radius*2)



















