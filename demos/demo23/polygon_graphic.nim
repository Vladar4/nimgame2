import
  nimgame2 / [
    types, graphic, draw, utils
  ],
  helpers,
  border_fill_graphic
type
  PolygonGraphic* = ref object of BorderFillGraphic
    points* : ref seq[Coord]


var points=newSeq[Coord](0)
proc drawPolygonGraphic*(self: PolygonGraphic,
                      pos: Coord = (0.0, 0.0),
                      angle: Angle = 0.0,
                      scale: Scale = 1.0,
                      center: Coord = (0.0, 0.0),
                      flip: Flip = Flip.none,
                      region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  var transform:Transform = (pos,angle,scale)
  let len =self.points[].len
  points.setLen(len)
  for i in 0..<len:
    points[i] = transform.point(self.points[i])
  if self.draw_filled:
    discard polygon(points,self.fill_color,DrawMode.filled)
  if self.draw_border:
    discard polygon(points,self.border_color,DrawMode.default)


method draw*(graphic: PolygonGraphic,
             pos: Coord = (0.0, 0.0),
             angle: Angle = 0.0,
             scale: Scale = 1.0,
             center: Coord = (0.0, 0.0),
             flip: Flip = Flip.none,
             region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  drawPolygonGraphic(graphic, pos, angle, scale, center, flip, region)


method dim*(self:PolygonGraphic):Dim=
  var
    x1=0.0
    x2=0.0
    y1=0.0
    y2=0.0
  for p in self.points[]:
    x1=min(x1,p.x)
    x2=max(x2,p.x)
    y1=min(y1,p.y)
    y2=max(y2,p.y)
  var
    w=x2-x1
    h=y2-y1
  return (w,h)


proc initPolygonGraphic*(self:PolygonGraphic)=
  self.initBorderFillGraphic()
  new self.points
  self.points[]= @[]
  self.fill_color= ColorPurple ## Traditional visual debugging color
  self.border_color= ColorPink


proc newPolygonGraphic*(): PolygonGraphic=
  new result
  result.initPolygonGraphic()

