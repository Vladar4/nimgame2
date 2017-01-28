# nimgame2/tilemap.nim
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
  collider, entity, graphic, types, utils


const
  DefaultTileScale: Scale = 1.02


type
  TileMap* = ref object of Entity
    map*: seq[seq[int]]
    passable*: seq[int] ##  The list of tile indexes without collisions
    tileScale*: Scale   ##  \
      ##  The scaling of individual tiles, mostly used for gap removal. \
      ##  Increase on scales vastly different from `1.0`. \
      ##  Set to `1.0` if your map isn't rotating or scaling.

  TileCollider* = ref object of Collider
    tiles*: seq[BoxCollider]



#=========#
# TileMap #
#=========#

proc initTileMap*(tilemap: TileMap) =
  tilemap.initEntity()
  tilemap.map = @[]
  tilemap.passable = @[]
  tilemap.tileScale = 1 #DefaultTileScale


proc newTileMap*(): TileMap =
  result = new TileMap
  result.initTileMap()



proc dimTiles*(tilemap: TileMap): Dim =
  ##  ``Return`` dimensions of the ``tilemap``, calculated from its ``map``
  ##  (in tiles).
  ##
  result = (0, 0)
  for row in tilemap.map:
    if result.w < row.len:
      result.w = row.len
    inc result.h


proc dim*(tilemap: TileMap): Dim {.inline.} =
  ##  ``Return`` dimensions of the ``tilemap``, calculated from its ``map``
  ##  (in pixels).
  ##
  result = tilemap.dimTiles * tilemap.sprite.dim


proc centrify*(tilemap: TileMap, hor = HAlign.center, ver = VAlign.center) =
  ##  Set ``tilemap``'s ``center``, according to the given align.
  ##
  ##  ``hor`` Horisontal align: left, center, or right
  ##
  ##  ``ver`` Vertical align: top, center, or bottom
  ##
  if tilemap.sprite == nil:
    return

  var dim = tilemap.dim

  # horisontal align
  tilemap.center.x = case hor:
  of HAlign.left:   0.0
  of HAlign.center: dim.w / 2
  of HAlign.right:  dim.w.float - 1

  # vertical align
  tilemap.center.y = case ver:
  of VAlign.top:    0.0
  of VAlign.center: dim.h / 2
  of VAlign.bottom: dim.h.float - 1


proc renderTileMap*(tilemap: TileMap) =
  if not (tilemap.graphic == nil) and
     not (tilemap.sprite == nil) and
     tilemap.visible:
    var pos: Coord
    let
      scale = tilemap.tileScale
      absScale = tilemap.absScale
      drawScale = scale * absScale
      dim: Coord = tilemap.sprite.dim * absScale
      offset: Coord = - (scale - 1) * tilemap.sprite.dim * absScale / 2.0
      drawCenter: Coord = tilemap.center / scale

    for y in 0..tilemap.map.high:
      pos.y = y.float * dim.y + offset.y

      for x in 0..tilemap.map[y].high:
        pos.x = x.float * dim.x + offset.x

        # Draw
        tilemap.graphic.draw(tilemap.absPos + pos.rotate(tilemap.absRot),
                             tilemap.absRot,
                             drawScale,
                             drawCenter,
                             tilemap.flip,
                             tilemap.sprite.frames[tilemap.map[y][x]])


method render*(tilemap: TileMap) =
  tilemap.renderTileMap()


#==============#
# TileCollider #
#==============#

proc init*(t: TileCollider, parent: TileMap, pos: Coord = (0, 0),
           dim: Dim = (0, 0)) =
  Collider(t).init(parent, pos)
  t.tiles = @[]

  let
    scale = parent.tileScale
    dim: Coord = parent.sprite.dim
    offset: Coord = dim * scale - dim * scale / 2.0

  var position: Coord

  for y in 0..parent.map.high:
    position.y = dim.y * y.float + offset.y

    for x in 0..parent.map[y].high:
      if parent.map[y][x] notin parent.passable:
        position.x = dim.x * x.float + offset.x
        t.tiles.add(newBoxCollider(parent, position, dim))


proc newTileCollider*(parent: TileMap, pos: Coord = (0, 0),
                      dim: Dim = (0, 0)): TileCollider =
  result = new TileCollider
  result.init(parent, pos, dim)


method render*(t: TileCollider) =
  for tile in t.tiles:
    tile.render()
  t.renderCollider()


proc initCollider*(tilemap: TileMap) =
  tilemap.collider = newTileCollider(tilemap, (0, 0), tilemap.sprite.dim)


# with Collider

method collide*(t: TileCollider, a: Collider): bool =
  for tile in t.tiles:
    if tile.collide(a):
      return true
  return false


method collide*(a: Collider, t: TileCollider): bool {.inline.} =
  collide(t, a)


# with BoxCollider

method collide*(t: TileCollider, b: BoxCollider): bool =
  for tile in t.tiles:
    if tile.collide(b):
      return true
  return false


method collide*(b: BoxCollider, t: TileCollider): bool {.inline.} =
  collide(t, b)


# with CircleCollider

method collide*(t: TileCollider, c: CircleCollider): bool =
  for tile in t.tiles:
    if tile.collide(c):
      return true
  return false


method collide*(c: CircleCollider, t: TileCollider): bool {.inline.} =
  collide(t, c)


# with LineCollider

method collide*(t: TileCollider, d: LineCollider): bool =
  for tile in t.tiles:
    if tile.collide(d):
      return true
  return false


method collide*(d: LineCollider, t: TileCollider): bool {.inline.} =
  collide(t, d)


# with PolyCollider

method collide*(t: TileCollider, p: PolyCollider): bool =
  for tile in t.tiles:
    if tile.collide(p):
      return true
  return false


method collide*(p: PolyCollider, t: TileCollider): bool {.inline.} =
  collide(t, p)


# with TileCollider

method collide*(t1, t2: TileCollider): bool =
  for tile in t1.tiles:
    if t2.collide(tile):
      return true
  return false
