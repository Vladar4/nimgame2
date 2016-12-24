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
  entity, types, utils


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


############
# Collider #
############

proc init*(a: Collider, parent: Entity, pos: Coord = (0, 0)) =
  a.parent = parent
  a.pos = pos


proc newCollider*(parent: Entity, pos: Coord = (0, 0)): Collider =
  result = new Collider
  result.init(parent, pos)


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


# Box - Point
method collide*(b: BoxCollider, a: Collider): bool =
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


# Circle - Point
method collide*(c: CircleCollider, a: Collider): bool =
  return collide(a, c)


# Circle - Box
method collide*(c: CircleCollider, b: BoxCollider): bool =
  return collide(b, c)


# Circle - Circle
method collide*(c1, c2: CircleCollider): bool {.inline.} =
  return distance(c1.position, c2.position) < (c1.radius + c2.radius)

