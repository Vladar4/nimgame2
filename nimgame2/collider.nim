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


##  Collider types are declared in `entity.nim`.
##


###########
# Private #
###########

template position(a: Collider): Coord =
  (a.parent.pos + a.parent.center + a.pos)


template right(b: BoxCollider): float =
  (b.position.x + b.dim.w.float)


template bottom(b: BoxCollider): float =
  (b.position.y + b.dim.h.float)


############
# Collider #
############

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
  return ((a.position.x >= b.position.x) and (a.position.x <= b.right)) and
         ((a.position.y >= b.position.y) and (a.position.y <= b.bottom))


# Point - Circle
method collide*(a: Collider, c: CircleCollider): bool {.inline.} =
  return distance(a.position, c.position) <= c.radius


# Point - Line
method collide*(a: Collider, d: LineCollider): bool =
  let
    pos0 = a.position
    pos1 = rotateEx(d.pos, d.parent.center, d.parent.pos, d.parent.rot)
    pos2 = rotateEx(d.pos2, d.parent.center, d.parent.pos, d.parent.rot)
  if distance(pos0, pos1, pos2) > 1.0:
    return false
  if distance(pos0, pos1) + distance(pos0, pos2) >= distance(pos1, pos2) + 1.0:
    return false
  else:
    return true


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
  discard #TODO


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
  discard #TODO


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
  discard #TODO

