# nimgame2/groupgraphic.nim
# Copyright (c) 2016-2021 Vladimir Arabadzhi (Vladar)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# vladar4@gmail.com
# https://github.com/Vladar4

import
  graphic,
  types


type
  #GraphicElement* = tuple[graphic: Graphic, offset: CoordInt]

  GraphicGroup* = ref object of Graphic ##  \
    ##  Allows to combine multiple Graphic objects into a single one.
    ##  Specify individual offsets through graphic.offset field.
    list*: seq[Graphic]


proc initGraphicGroup*(group: GraphicGroup) =
  group.list = @[]


proc newGraphicGroup*(): GraphicGroup =
  new result
  result.initGraphicGroup()


method w*(group: GraphicGroup): int =
  var
    left = 0.0
    right = 0.0
  for e in group.list:
    if left > e.offset.x:
      left = e.offset.x
    let w = e.w.float + e.offset.x
    if right < w:
      right = w
  int(right - left)


method h*(group: GraphicGroup): int =
  var
    top = 0.0
    bottom = 0.0
  for e in group.list:
    if top > e.offset.y:
      top = e.offset.y
    let h = e.h.float + e.offset.y
    if bottom < h:
      bottom = h
  int(bottom - top)


method dim*(group: GraphicGroup): Dim =
  (group.w, group.h)


method draw*(group: GraphicGroup,
             pos: Coord = (0.0, 0.0),
             angle: Angle = 0.0,
             scale: Scale = 1.0,
             center: Coord = (0.0, 0.0),
             flip: Flip = Flip.none,
             region: Rect = Rect(x: 0, y: 0, w: 0, h: 0)) =
  for e in group.list:
    e.draw(pos, angle, scale, center, flip, region)

