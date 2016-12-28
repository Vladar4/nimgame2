# nimgame2/collider.nim
# Copyright (c) 2016 Vladar
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
# Vladar vladar4@gmail.com


import
  math,
  nimgame, draw, entity, settings, types, utils

from fenv import epsilon
let Eps = epsilon(float)


##  Collider types are declared in `entity.nim`.
##


###########
# Private #
###########

template position(a: Collider): Coord =
  (a.parent.pos + a.pos)


template right(b: BoxCollider): float =
  (b.position.x + b.dim.w.float)


template bottom(b: BoxCollider): float =
  (b.position.y + b.dim.h.float)


template pointInBox(p: Coord, b: BoxCollider): bool =
  ##  ``Return`` `true` if ``p`` is contained in ``b``, or `false` otherwise.
  ##
  ( ((p.x >= b.position.x) and (p.x <= b.right)) and
    ((p.y >= b.position.y) and (p.y <= b.bottom)) )


proc linesIntersect(p1, p2, p3, p4: Coord): bool =
  ##  ``Return`` `true` if line segment `p1`-`p2` intersects with `p3`-`p4`,
  ##  or `false` otherwise.
  ##
  let
    a = ( (p4.x - p3.x) * (p1.y - p3.y) -
          (p4.y - p3.y) * (p1.x - p3.x) ) /
        ( (p4.y - p3.y) * (p2.x - p1.x) -
          (p4.x - p3.x) * (p2.y - p1.y) )
    b = ( (p2.x - p1.x) * (p1.y - p3.y) -
          (p2.y - p1.y) * (p1.x - p3.x) ) /
        ( (p4.y - p3.y) * (p2.x - p1.x) -
          (p4.x - p3.x) * (p2.y - p1.y) )
  return ( a >= 0 and a <= 1 ) and (b >= 0 and b <= 1)


####################
# Collider (Point) #
####################

proc init*(a: Collider, parent: Entity, pos: Coord = (0, 0)) =
  a.parent = parent
  a.pos = pos


proc newCollider*(parent: Entity, pos: Coord = (0, 0)): Collider =
  result = new Collider
  result.init(parent, pos)


proc renderCollider*(a: Collider, renderer: Renderer) =
  let
    pos = a.position
    rad = 4.0
  discard renderer.hline(pos - (rad, 0.0), 8, colliderOutlineColor)
  discard renderer.vline(pos - (0.0, rad), 8, colliderOutlineColor)
  discard renderer.circle(pos, rad, colliderOutlineColor)


method render*(a: Collider, renderer: Renderer) {.base.} =
  a.renderCollider(renderer)


# Point - Point
method collide*(a1, a2: Collider): bool {.base, inline.} =
  return a1.position == a2.position


# Point - Box
method collide*(a: Collider, b: BoxCollider): bool {.inline.} =
  return pointInBox(a.position, b)


# Point - Circle
method collide*(a: Collider, c: CircleCollider): bool {.inline.} =
  return distance(a.position, c.position) <= c.radius


# Point - Line
method collide*(a: Collider, d: LineCollider): bool =
  let
    pos0 = a.position
    pos1 = rotateEx(d.pos, d.parent.center, d.parent.pos, d.parent.rot)
    pos2 = rotateEx(d.pos2, d.parent.center, d.parent.pos, d.parent.rot)
  if distanceToLine(pos0, pos1, pos2) >= 1.0:
    return false
  if distance(pos0, pos1) + distance(pos0, pos2) >= distance(pos1, pos2) + 1.0:
    return false
  else:
    return true


# Point - Poly
method collide*(a: Collider, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(a, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(a, LineCollider(parent: p.parent,
                                   pos: p.points[0],
                                   pos2: p.points[1]))
  let
    p0 = rotateEx(a.pos, a.parent.center, a.parent.pos, a.parent.rot)
  var
    i = 0
    j = p.points.high
    c = 0
  while i < p.points.len:
    let
      pi = rotateEx(p.points[i], p.parent.center, p.parent.pos, p.parent.rot)
      pj = rotateEx(p.points[j], p.parent.center, p.parent.pos, p.parent.rot)
    if ( ((pi.y <= p0.y) and (p0.y < pj.y)) or
         ((pj.y <= p0.y) and (p0.y < pi.y)) ) and
       ( p0.x < (pj.x - pi.x) * (p0.y - pi.y) / (pj.y - pi.y) + pi.x ):
      c = if c == 0: 1 else: 0
    # increment
    j = i
    inc i
  return c > 0


###############
# BoxCollider #
###############

proc init*(b: BoxCollider, parent: Entity, pos: Coord = (0, 0),
           dim: Dim = (0, 0)) =
  Collider(b).init(parent, pos)
  b.dim = dim


proc newBoxCollider*(parent: Entity, pos: Coord = (0, 0),
                     dim: Dim = (0, 0)): BoxCollider =
  result = new BoxCollider
  result.init(parent, pos, dim)


method render*(b: BoxCollider, renderer: Renderer) =
  discard renderer.rect(b.position, (b.right, b.bottom), colliderOutlineColor)
  b.renderCollider(renderer)


# Box - Point
method collide*(b: BoxCollider, a: Collider): bool {.inline.} =
  return collide(a, b)


# Box - Box
method collide*(b1, b2: BoxCollider): bool =
  if b1.position.x > b2.right: return false
  if b1.right < b2.position.x: return false
  if b1.position.y > b2.bottom: return false
  if b1.bottom < b2.position.y: return false
  return true


# Box - Circle
method collide*(b: BoxCollider, c: CircleCollider): bool =
  let
    right = b.right
    bottom = b.bottom
  var
    closest: Coord
  closest.x = if b.position.x > c.position.x: b.position.x
              elif right < c.position.x: right
              else: c.position.x
  closest.y = if b.position.y > c.position.y: b.position.y
              elif bottom < c.position.y: bottom
              else: c.position.y
  return distance(c.position, closest) < c.radius


# Box - Line
method collide*(b: BoxCollider, d: LineCollider): bool =
  let
    b1 = b.position
    b2 = (b.right, b1.y)
    b3 = (b.right, b.bottom)
    b4 = (b1.x, b.bottom)
    d1 = rotateEx(d.pos, d.parent.center, d.parent.pos, d.parent.rot)
    d2 = rotateEx(d.pos2, d.parent.center, d.parent.pos, d.parent.rot)
  if pointInBox(d1, b):
    return true
  elif pointInBox(d2, b):
    return true
  elif linesIntersect(b1, b2, d1, d2):
    return true
  elif linesIntersect(b2, b3, d1, d2):
    return true
  elif linesIntersect(b3, b4, d1, d2):
    return true
  else:
    return false


# Box - Poly
method collide*(b: BoxCollider, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(b, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(b, LineCollider(parent: p.parent,
                                   pos: p.points[0],
                                   pos2: p.points[1]))
  var
    i = 0
    j = p.points.high
  while i < p.points.len:
    if collide(b, LineCollider(parent: p.parent,
                               pos: p.points[i],
                               pos2: p.points[j])):
      return true
    # increment
    j = i
    inc i
  return false


##################
# CircleCollider #
##################

proc init*(c: CircleCollider, parent: Entity, pos: Coord = (0, 0),
           radius: float = 0) =
  Collider(c).init(parent, pos)
  c.radius = radius


proc newCircleCollider*(parent: Entity, pos: Coord = (0, 0),
                        radius: float = 0): CircleCollider =
  result = new CircleCollider
  result.init(parent, pos, radius)


method render*(c: CircleCollider, renderer: Renderer) =
  discard renderer.circle(c.position, c.radius, colliderOutlineColor)
  c.renderCollider(renderer)


# Circle - Point
method collide*(c: CircleCollider, a: Collider): bool {.inline.} =
  return collide(a, c)


# Circle - Box
method collide*(c: CircleCollider, b: BoxCollider): bool {.inline.} =
  return collide(b, c)


# Circle - Circle
method collide*(c1, c2: CircleCollider): bool {.inline.} =
  return distance(c1.position, c2.position) < (c1.radius + c2.radius)


# Circle - Line
method collide*(c: CircleCollider, d: LineCollider): bool =
  let
    cc = c.position
    d1 = rotateEx(d.pos, d.parent.center, d.parent.pos, d.parent.rot)
    d2 = rotateEx(d.pos2, d.parent.center, d.parent.pos, d.parent.rot)
    dd = d2 - d1
    a = pow(dd.x, 2) + pow(dd.y, 2)
    b = 2 * (dd.x * (d1.x - cc.x) + dd.y * (d1.y - cc.y))
    c = pow(cc.x, 2) + pow(cc.y, 2) +
        pow(d1.x, 2) + pow(d1.y, 2) -
        2 * (cc.x * d1.x + cc.y * d1.y) -
        pow(c.radius, 2)
    i = b * b - 4 * a * c;
  if i < 0:
    return false
  elif abs(a) < Eps:
    return false
  else:
    let
      a2 = 2 * a
      ri = sqrt(i)
      n1 = (-b + ri) / a2
      n2 = (-b - ri) / a2
    if ((n1 < 0) and (n2 < 0)) or ((n1 > 1) and (n2 > 1)):
      return false
    else:
      return true

# Circle - Poly
method collide*(c: CircleCollider, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(c, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(c, LineCollider(parent: p.parent,
                                   pos: p.points[0],
                                   pos2: p.points[1]))
  var
    i = 0
    j = p.points.high
  while i < p.points.len:
    if collide(c, LineCollider(parent: p.parent,
                               pos: p.points[i],
                               pos2: p.points[j])):
      return true
    # increment
    j = i
    inc i
  return false


#################
# Line Collider #
#################

proc init*(d: LineCollider, parent: Entity, pos: Coord = (0, 0),
           pos2: Coord = (0, 0)) =
  Collider(d).init(parent, pos)
  d.pos2 = pos2


proc newLineCollider*(parent: Entity, pos: Coord = (0, 0),
                      pos2: Coord = (0, 0)): LineCollider =
  result = new LineCollider
  result.init(parent, pos, pos2)


method render*(d: LineCollider, renderer: Renderer) =
  let
    pos1 = rotateEx(d.pos, d.parent.center, d.parent.pos, d.parent.rot)
    pos2 = rotateEx(d.pos2, d.parent.center, d.parent.pos, d.parent.rot)

  discard renderer.line(pos1, pos2, colliderOutlineColor)
  d.renderCollider(renderer)


# Line - Point
method collide*(d: LineCollider, a: Collider): bool {.inline.} =
  collide(a, d)


# Line - Box
method collide*(d: LineCollider, b: BoxCollider): bool {.inline.} =
  collide(b, d)


# Line - Circle
method collide*(d: LineCollider, c: CircleCollider): bool {.inline.} =
  collide(c, d)


# Line - Line
method collide*(d1, d2: LineCollider): bool =
  let
    p1 = rotateEx(d1.pos, d1.parent.center, d1.parent.pos, d1.parent.rot)
    p2 = rotateEx(d1.pos2, d1.parent.center, d1.parent.pos, d1.parent.rot)
    p3 = rotateEx(d2.pos, d2.parent.center, d2.parent.pos, d2.parent.rot)
    p4 = rotateEx(d2.pos2, d2.parent.center, d2.parent.pos, d2.parent.rot)
  return linesIntersect(p1, p2, p3, p4)


# Line - Poly
method collide*(d: LineCollider, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(d, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(d, LineCollider(parent: p.parent,
                                   pos: p.points[0],
                                   pos2: p.points[1]))

  if collide(Collider(parent: d.parent, pos: d.pos), p):
    return true
  if collide(Collider(parent: d.parent, pos: d.pos2), p):
    return true
  var
    i = 0
    j = p.points.high
  while i < p.points.len:
    if collide(d, LineCollider(parent: p.parent,
                               pos: p.points[i],
                               pos2: p.points[j])):
      return true
    # increment
    j = i
    inc i
  return false


################
# PolyCollider #
################

proc init*(p: PolyCollider, parent: Entity, pos: Coord = (0, 0),
           points: openarray[Coord]) =
  Collider(p).init(parent, pos)
  p.points = @points


proc newPolyCollider*(parent: Entity, pos: Coord = (0, 0),
                      points: openarray[Coord]): PolyCollider =
  result = new PolyCollider
  result.init(parent, pos, points)


method render*(p: PolyCollider, renderer: Renderer) =
  if p.points.len < 1:    # No points
    return
  elif p.points.len < 2:  # One point
    render(Collider(parent: p.parent, pos: p.points[0]),
           renderer)
  elif p.points.len < 3:  # Two points
    render(LineCollider(parent: p.parent, pos: p.points[0], pos2: p.points[1]),
           renderer)
  var
    i = 0
    j = p.points.high
  while i < p.points.len:
    let
      pi = rotateEx(p.points[i], p.parent.center, p.parent.pos, p.parent.rot)
      pj = rotateEx(p.points[j], p.parent.center, p.parent.pos, p.parent.rot)
    discard renderer.line(pi, pj, colliderOutlineColor)
    # increment
    j = i
    inc i
  p.renderCollider(renderer)


# Poly - Point
method collide*(p: PolyCollider, a: Collider): bool {.inline.} =
  collide(a, p)


# Poly - Box
method collide*(p: PolyCollider, b: BoxCollider): bool {.inline.} =
  collide(b, p)


# Poly - Circle
method collide*(p: PolyCollider, c: CircleCollider): bool {.inline.} =
  collide(c, p)


# Poly - Line
method collide*(p: PolyCollider, d: LineCollider): bool {.inline.} =
  collide(d, p)


# Poly - Poly
method collide*(p1, p2: PolyCollider): bool =
  if p1.points.len < 1 or p2.points.len < 1:   # P1 or P2 no points
    return false
  elif p1.points.len < 2: # P1 one point
    return collide(Collider(parent: p1.parent,
                            pos: p1.points[0]),
                   p2)
  elif p2.points.len < 2: # P2 one point
    return collide(Collider(parent: p2.parent,
                            pos: p2.points[0]),
                   p1)
  elif p1.points.len < 3: # P1 two points
    return collide(LineCollider(parent: p1.parent,
                                pos: p1.points[0],
                                pos2: p1.points[1]),
                   p2)
  elif p2.points.len < 3: # P2 two points
    return collide(LineCOllider(parent: p2.parent,
                                pos: p2.points[0],
                                pos2: p2.points[1]),
                   p1)
  var
    i = 0
    j = p1.points.high
  while i < p1.points.len:
    if collide(LineCollider(parent: p1.parent,
                            pos: p1.points[i],
                            pos2: p1.points[j]),
               p2):
      return true
    # increment
    j = i
    inc i
  return false

