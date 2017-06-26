# nimgame2/collider.nim
# Copyright (c) 2016-2017 Vladar
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


#=========#
# Private #
#=========#

template position(a: Collider): Coord =
  if a.parent.absRot == 0:
    (a.parent.absPos + a.pos * a.parent.absScale)
  else:
    rotate(a.pos * a.parent.absScale, a.parent.absPos, a.parent.absRot)


template scaled(n: float, a: Collider): float =
  (n * a.parent.absScale)


template scaled(n: int, a: Collider): int =
  int(n.float * a.parent.absScale)


template scaled(n: Coord, a: Collider): Coord =
  (n.x * a.parent.absScale, n.y * a.parent.absScale)


template left(b: BoxCollider): float =
  (b.position.x - b.dim.w.scaled(b) / 2)


template right(b: BoxCollider): float =
  (b.position.x + b.dim.w.scaled(b) / 2)


template top(b: BoxCollider): float =
  (b.position.y - b.dim.h.scaled(b) / 2)


template bottom(b: BoxCollider): float =
  (b.position.y + b.dim.h.scaled(b) / 2)


template pointInBox(p: Coord, b: BoxCollider): bool =
  ##  ``Return`` `true` if ``p`` is contained in ``b``, or `false` otherwise.
  ##
  ( ((p.x >= b.left) and (p.x <= b.right)) and
    ((p.y >= b.top) and (p.y <= b.bottom)) )


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


#==================#
# Coord collisions #
#==================#

# Coord - Coord
template collide*(pos1, pos2: Coord): bool =
  pos1 == pos2


# Coord - Point
method collide*(pos: Coord, a: Collider): bool {.base, inline.} =
  pos == a.position


# Coord - Box
method collide*(pos: Coord, b: BoxCollider): bool {.inline.} =
  pointInBox(pos, b)


# Coord - Circle
method collide*(pos: Coord, c: CircleCollider): bool {.inline.} =
  distance(pos, c.position) <= c.radius.scaled(c)


# Coord - Line
method collide*(pos: Coord, d: LineCollider): bool =
  let
    dpPosition = d.parent.absPos
    dpRotation = d.parent.absRot
    pos1 = rotate(d.pos.scaled(d), dpPosition, dpRotation)
    pos2 = rotate(d.pos2.scaled(d), dpPosition, dpRotation)
  if distanceToLine(pos, pos1, pos2) >= 0.5:
    return false
  if distance(pos, pos1) + distance(pos, pos2) >= distance(pos1, pos2) + 0.5:
    return false
  else:
    return true


# Coord - Poly
method collide*(pos: Coord, p: PolyCollider): bool =
  if p.points.len < 1:    # No points
    return false
  elif p.points.len < 2:  # One point
    return collide(pos, Collider(parent: p.parent,
                               pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    return collide(pos, LineCollider(parent: p.parent,
                                     pos: p.points[0],
                                     pos2: p.points[1]))
  else:
    let
      ppPosition = p.parent.absPos
      ppRotation = p.parent.absRot
    var
      i = 0
      j = p.points.high
      c = 0
    while i < p.points.len:
      let
        pi = rotate(p.points[i].scaled(p), ppPosition, ppRotation)
        pj = rotate(p.points[j].scaled(p), ppPosition, ppRotation)
      if ( ((pi.y <= pos.y) and (pos.y < pj.y)) or
          ((pj.y <= pos.y) and (pos.y < pi.y)) ) and
        ( pos.x < (pj.x - pi.x) * (pos.y - pi.y) / (pj.y - pi.y) + pi.x ):
        c = if c == 0: 1 else: 0
      # increment
      j = i
      inc i
    return c > 0


#==================#
# Collider (Point) #
#==================#

proc init*(a: Collider, parent: Entity, pos: Coord = (0, 0)) =
  a.parent = parent
  a.pos = pos
  a.tags = @[]


proc newCollider*(parent: Entity, pos: Coord = (0, 0)): Collider =
  result = new Collider
  result.init(parent, pos)


proc renderCollider*(a: Collider) =
  let
    pos = a.position
    rad = 4.0
  discard hline(pos - (rad, 0.0), 8, colliderOutlineColor)
  discard vline(pos - (0.0, rad), 8, colliderOutlineColor)
  discard circle(pos, rad, colliderOutlineColor)


method render*(a: Collider) {.base.} =
  a.renderCollider()


# Point - Coord
method collide*(a: Collider, pos: Coord): bool {.base, inline.} =
  return collide(pos, a)


# Point - Point
method collide*(a1, a2: Collider): bool {.base, inline.} =
  return collide(a1.position, a2.position)


# Point - Box
method collide*(a: Collider, b: BoxCollider): bool {.inline.} =
  return collide(a.position, b)


# Point - Circle
method collide*(a: Collider, c: CircleCollider): bool {.inline.} =
  return collide(a.position, c)


# Point - Line
method collide*(a: Collider, d: LineCollider): bool =
  return collide(a.position, d)


# Point - Poly
method collide*(a: Collider, p: PolyCollider): bool =
  return collide(a.position, p)


#=============#
# BoxCollider #
#=============#

proc init*(b: BoxCollider, parent: Entity, pos: Coord = (0, 0),
           dim: Dim = (0, 0)) =
  Collider(b).init(parent, pos)
  b.dim = dim


proc newBoxCollider*(parent: Entity, pos: Coord = (0, 0),
                     dim: Dim = (0, 0)): BoxCollider =
  result = new BoxCollider
  result.init(parent, pos, dim)


method render*(b: BoxCollider) =
  discard rect((b.left, b.top), (b.right, b.bottom), colliderOutlineColor)
  b.renderCollider()


# Box - Coord
method collide*(b: BoxCollider, pos: Coord): bool {.inline.} =
  return collide(pos, b)


# Box - Point
method collide*(b: BoxCollider, a: Collider): bool {.inline.} =
  return collide(a, b)


# Box - Box
method collide*(b1, b2: BoxCollider): bool =
  if b1.left > b2.right: return false
  if b1.right < b2.left: return false
  if b1.top > b2.bottom: return false
  if b1.bottom < b2.top: return false
  return true


# Box - Circle
method collide*(b: BoxCollider, c: CircleCollider): bool =
  let
    left = b.left
    right = b.right
    top = b.top
    bottom = b.bottom
    cpos = c.position
  var
    closest: Coord
  closest.x = if left > cpos.x: left
              elif right < cpos.x: right
              else: cpos.x
  closest.y = if top > cpos.y: top
              elif bottom < cpos.y: bottom
              else: cpos.y
  return distance(cpos, closest) < c.radius.scaled(c)


# Box - Line
method collide*(b: BoxCollider, d: LineCollider): bool =
  let
    b1 = (x: b.left, y: b.top)
    b2 = (b.right, b1.y)
    b3 = (b.right, b.bottom)
    b4 = (b1.x, b.bottom)
    dpPosition = d.parent.absPos
    dpRotation = d.parent.absRot
    d1 = rotate(d.pos.scaled(d), dpPosition, dpRotation)
    d2 = rotate(d.pos2.scaled(d), dpPosition, dpRotation)
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
  else:
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


#================#
# CircleCollider #
#================#

proc init*(c: CircleCollider, parent: Entity, pos: Coord = (0, 0),
           radius: float = 0) =
  Collider(c).init(parent, pos)
  c.radius = radius


proc newCircleCollider*(parent: Entity, pos: Coord = (0, 0),
                        radius: float = 0): CircleCollider =
  result = new CircleCollider
  result.init(parent, pos, radius)


method render*(c: CircleCollider) =
  discard circle(c.position, c.radius.scaled(c), colliderOutlineColor)
  c.renderCollider()


# Circle - Coord
method collide*(c: CircleCollider, pos: Coord): bool {.inline.} =
  return collide(pos, c)


# Circle - Point
method collide*(c: CircleCollider, a: Collider): bool {.inline.} =
  return collide(a, c)


# Circle - Box
method collide*(c: CircleCollider, b: BoxCollider): bool {.inline.} =
  return collide(b, c)


# Circle - Circle
method collide*(c1, c2: CircleCollider): bool {.inline.} =
  return distance(c1.position, c2.position) <
         (c1.radius.scaled(c1) + c2.radius.scaled(c2))


# Circle - Line
method collide*(c: CircleCollider, d: LineCollider): bool =
  let
    cc = c.position
    dpPosition = d.parent.absPos
    dpRotation = d.parent.absRot
    d1 = rotate(d.pos.scaled(d), dpPosition, dpRotation)
    d2 = rotate(d.pos2.scaled(d), dpPosition, dpRotation)
    dd = d2 - d1
    a = pow(dd.x, 2) + pow(dd.y, 2)
    b = 2 * (dd.x * (d1.x - cc.x) + dd.y * (d1.y - cc.y))
    c = pow(cc.x, 2) + pow(cc.y, 2) +
        pow(d1.x, 2) + pow(d1.y, 2) -
        2 * (cc.x * d1.x + cc.y * d1.y) -
        pow(c.radius.scaled(c), 2)
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
  else:
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


#===============#
# Line Collider #
#===============#

proc init*(d: LineCollider, parent: Entity, pos: Coord = (0, 0),
           pos2: Coord = (0, 0)) =
  Collider(d).init(parent, pos)
  d.pos2 = pos2


proc newLineCollider*(parent: Entity, pos: Coord = (0, 0),
                      pos2: Coord = (0, 0)): LineCollider =
  result = new LineCollider
  result.init(parent, pos, pos2)


method render*(d: LineCollider) =
  let
    dpPosition = d.parent.absPos
    dpRotation = d.parent.absRot
    pos1 = rotate(d.pos.scaled(d), dpPosition, dpRotation)
    pos2 = rotate(d.pos2.scaled(d), dpPosition, dpRotation)
  discard line(pos1, pos2, colliderOutlineColor)
  d.renderCollider()


# Line - Coord
method collide*(d: LineCollider, pos: Coord): bool {.inline.} =
  collide(pos, d)


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
    d1pPosition = d1.parent.absPos
    d1pRotation = d1.parent.absRot
    d2pPosition = d2.parent.absPos
    d2pRotation = d2.parent.absRot
    p1 = rotate(d1.pos.scaled(d1), d1pPosition, d1pRotation)
    p2 = rotate(d1.pos2.scaled(d1), d1pPosition, d1pRotation)
    p3 = rotate(d2.pos.scaled(d2), d2pPosition, d2pRotation)
    p4 = rotate(d2.pos2.scaled(d2), d2pPosition, d2pRotation)
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
  else:
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


#==============#
# PolyCollider #
#==============#

proc init*(p: PolyCollider, parent: Entity, pos: Coord = (0, 0),
           points: openarray[Coord]) =
  Collider(p).init(parent, pos)
  p.points = @points


proc newPolyCollider*(parent: Entity, pos: Coord = (0, 0),
                      points: openarray[Coord]): PolyCollider =
  result = new PolyCollider
  result.init(parent, pos, points)


method render*(p: PolyCollider) =
  if p.points.len < 1:    # No points
    return
  elif p.points.len < 2:  # One point
    render(Collider(parent: p.parent, pos: p.points[0]))
  elif p.points.len < 3:  # Two points
    render(LineCollider(parent: p.parent, pos: p.points[0], pos2: p.points[1]))
  else:
    let
      ppPosition = p.parent.absPos
      ppRotation = p.parent.absRot
    var points: seq[Coord] = @[]
    for point in p.points:
      points.add(rotate(point.scaled(p), ppPosition, ppRotation))
    discard polygon(points, colliderOutlineColor)
    p.renderCollider()


# Poly - Coord
method collide*(p: PolyCollider, pos: Coord): bool {.inline.} =
  collide(pos, p)


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
  else:
    # check if polygons are close enough
    var
      max1 = 0.0
      max2 = 0.0
    for p in p1.points:
      let dp = distance(p1.pos, p)
      if dp > max1:
        max1 = dp
    for p in p2.points:
      let dp = distance(p2.pos, p)
      if dp > max2:
        max2 = dp
    if (max1 + max2) < distance(p1.pos, p2.pos):
      return false # not close enough

    # check for collision
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


#=======#
# Utils #
#=======#

proc intersect(a, b: seq[string]): bool =
  for item in a:
    if item in b:
      return true
  return false


iterator collisions(entity: Entity, list: seq[Entity]): Entity =
  for target in list:
    if target.collider == nil: continue # no collider on target
    if entity == target: continue # entity is target
    if target in entity.colliding: continue # already collided with target
    if entity.collider.tags.len == 0 or # no tags given
       entity.collider.tags.intersect(target.tags): # check for needed tags
      if collide(entity.collider, target.collider): # check for collision
        yield target


proc checkCollisions*(entity: Entity, list: seq[Entity]) =
  for target in entity.collisions(list):
    target.colliding.add(entity) # mark target as already collided with entity
    entity.onCollide(target)
    target.onCollide(entity)


proc isColliding*(entity: Entity, list: seq[Entity]): bool =
  for target in entity.collisions(list):
    return true
  return false


proc willCollide*(entity: Entity, pos: Coord, rot: Angle, scale: Scale): bool =
  let
    originalPos = entity.pos
    originalRot = entity.rot
    originalScale = entity.scale

  entity.pos = pos
  entity.rot = rot
  entity.scale = scale

  defer:
    entity.pos = originalPos
    entity.rot = originalRot
    entity.scale = scale

  result = isColliding(entity, entity.collisionEnvironment)

