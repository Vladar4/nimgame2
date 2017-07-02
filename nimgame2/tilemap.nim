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
  DefaultTileScale*: Scale = 1.02


type
  TileShow* = tuple[x: Slice[int], y: Slice[int]]

  TileMap* = ref object of Entity
    map*: seq[seq[int]] ##  Two-dimensional sequence of tile indexes
    fShow: TileShow     ##  Slice of what part of map to show
    hidden*: seq[int]   ##  The list of tile indexes to not render
    passable*: seq[int] ##  The list of tile indexes without colliders
    tileScale*: Scale   ##  \
      ##  The scaling of individual tiles, mostly used for gap removal. \
      ##  Increase on scales vastly different from `1.0`. \
      ##  Set to `1.0` if your map isn't rotating or scaling.

  TileCollider* = ref object of BoxCollider
    value*: int       ##  Tile kind value
    mapx*, mapy*: int ##  Map coordinates

  TileMapCollider* = ref object of Collider  ## Collider to use with TileMap
    tiles*: seq[TileCollider]  ##  Sequence of individual tile colliders


#=========#
# TileMap #
#=========#

proc init*(tilemap: TileMap, scaleFix = false) =
  tilemap.initEntity()
  tilemap.map = @[]
  tilemap.fShow = (0..0, 0..0)
  tilemap.hidden = @[]
  tilemap.passable = @[]
  tilemap.tileScale = if scaleFix: DefaultTileScale else: 1.0


proc newTileMap*(scaleFix = false): TileMap =
  ##  Create a new TileMap.
  ##
  ##  ``scaleFix``  set ``tileScale`` to ``DefaultTileScale`` if `true`,
  ##  or to `1.0` otherwise.
  ##
  result = new TileMap
  result.init(scaleFix)


proc show*(tilemap: TileMap): TileShow {.inline.} =
  ##  ``Return`` a currently shown slices of tiles.
  ##
  return tilemap.fShow


proc init*(t: TileMapCollider, parent: TileMap, pos: Coord = (0, 0), dim: Dim = (0, 0))
proc `show=`*(tilemap: TileMap, val: TileShow) =
  ##  Set new values for the shown slices of tiles.
  ##
  var show: TileShow
  show.y.a = if val.y.a < 0: 0 else: val.y.a
  show.y.b = if val.y.b > tilemap.map.high: tilemap.map.high else: val.y.b
  show.x.a = if val.x.a < 0: 0 else: val.x.a
  show.x.b = if val.x.b > tilemap.map[0].high: tilemap.map[0].high else: val.x.b
  tilemap.fShow = show

  # Update collider
  if tilemap.collider != nil:
    TileMapCollider(tilemap.collider).init(
      tilemap, (0.0, 0.0), tilemap.sprite.dim)


template updateShow(tilemap: TileMap) =
  ##  Updates ``TileMap.show`` property,
  ##  according to ``TileMap.map`` dimensions.
  ##
  if tilemap.fShow == (0..0, 0..0):
    tilemap.fShow = (x: 0..tilemap.map[0].high, y: 0..tilemap.map.high)


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


iterator tileIndex*(tilemap: TileMap, value: int): CoordInt =
  for y in 0..tilemap.map.high:
    for x in 0..tilemap.map[y].high:
      if tilemap.map[y][x] == value:
        yield (x, y)


proc firstTileIndex*(tilemap: TileMap, value: int): CoordInt =
  for i in tilemap.tileIndex(value):
    return i


proc tileIndex*(tilemap: TileMap, pos: Coord): CoordInt =
  let
    dim: Coord = tilemap.sprite.dim * tilemap.absScale
    offset: Coord = pos - tilemap.pos
  result = (
    int(offset.x / dim.x),
    int(offset.y / dim.y))


proc tilePos*(tilemap: TileMap, index: CoordInt): Coord =
  let
    dim: Coord = tilemap.sprite.dim * tilemap.absScale
    offset: Coord =
      - (tilemap.tileScale - 1) * tilemap.sprite.dim * tilemap.absScale / 2.0
  result = (
    index.x.float * dim.x + offset.x,
    index.y.float * dim.y + offset.y)


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

    tilemap.updateShow()
    for y in tilemap.fShow.y:
      pos.y = y.float * dim.y + offset.y

      for x in tilemap.fShow.x:
        pos.x = x.float * dim.x + offset.x

        let val = tilemap.map[y][x]

        if val in tilemap.hidden: # Do not render hidden tiles
          continue

        # Draw
        tilemap.graphic.draw(tilemap.absPos + pos.rotate(tilemap.absRot),
                             tilemap.absRot,
                             drawScale,
                             drawCenter,
                             tilemap.flip,
                             tilemap.sprite.frames[val])


method render*(tilemap: TileMap) =
  tilemap.renderTileMap()


#==============#
# TileCollider #
#==============#

proc init*(t: TileCollider,
           parent: TileMap, pos: Coord = (0, 0), dim: Dim = (0, 0),
           value, mapx, mapy: int) =
  BoxCollider(t).init(parent, pos, dim)
  t.value = value
  t.mapx = mapx
  t.mapy = mapy


proc newTileCollider*(parent: TileMap, pos: Coord = (0, 0), dim: Dim = (0, 0),
                      value, mapx, mapy: int): TileCollider =
  new result
  result.init(parent, pos, dim, value, mapx, mapy)


#=================#
# TileMapCollider #
#=================#

proc init*(t: TileMapCollider, parent: TileMap, pos: Coord = (0, 0),
           dim: Dim = (0, 0)) =
  Collider(t).init(parent, pos)
  t.tiles = @[]

  let
    scale = parent.tileScale
    spriteDim: Coord = parent.sprite.dim
    dim: Coord = spriteDim * scale
    offset: Coord = spriteDim / 2.0 - parent.center

  var position: Coord

  parent.updateShow()
  #for y in 0..parent.map.high:
  for y in parent.fShow.y:
    position.y = dim.y * y.float / scale + offset.y

    #for x in 0..parent.map[y].high:
    for x in parent.fShow.x:
      if parent.map[y][x] notin parent.passable:
        position.x = dim.x * x.float / scale + offset.x
        t.tiles.add(
          newTileCollider(parent, position, dim, parent.map[y][x], x, y))


proc newTileMapCollider*(parent: TileMap, pos: Coord = (0, 0),
                         dim: Dim = (0, 0)): TileMapCollider =
  ##  Create a ``TileMapCollider`` for the ``parent`` ``TileMap``.
  ##
  ##  Most of the times you should use ``initCollider()`` instead.
  ##
  ##  ``pos`` Collider's relative position. Usually `(0, 0)`.
  ##
  ##  ``dim`` Tile dimensions.
  ##
  result = new TileMapCollider
  result.init(parent, pos, dim)


method render*(t: TileMapCollider) =
  for tile in t.tiles:
    tile.render()
  t.renderCollider()


proc initCollider*(tilemap: TileMap) =
  ##  Initialize a collider for the ``tilemap``.
  ##
  tilemap.collider = newTileMapCollider(tilemap, (0, 0), tilemap.sprite.dim)


template collisionList*(t: TileMapCollider,
                        a: typed,
                        first: bool = false): seq[TileCollider] =
  ##  Get a list of collided ``TileColliders``.
  ##
  ##  ``a`` collision target (``Coord``, any ``Collider``, etc.)
  ##
  ##  ``first`` If true, return after the first detected collision.
  ##
  var result: seq[TileCollider] = @[]
  for tile in t.tiles:
    if tile.collide(a):
      result.add(tile)
      if first: break
  result


# with Coord

method collide*(t: TileMapCollider, pos: Coord): bool =
  for tile in t.tiles:
    if tile.collide(pos):
      return true
  return false


# with Collider

method collide*(t: TileMapCollider, a: Collider): bool =
  for tile in t.tiles:
    if tile.collide(a):
      return true
  return false


method collide*(a: Collider, t: TileMapCollider): bool {.inline.} =
  collide(t, a)


# with BoxCollider

method collide*(t: TileMapCollider, b: BoxCollider): bool =
  for tile in t.tiles:
    if tile.collide(b):
      return true
  return false


method collide*(b: BoxCollider, t: TileMapCollider): bool {.inline.} =
  collide(t, b)


# with CircleCollider

method collide*(t: TileMapCollider, c: CircleCollider): bool =
  for tile in t.tiles:
    if tile.collide(c):
      return true
  return false


method collide*(c: CircleCollider, t: TileMapCollider): bool {.inline.} =
  collide(t, c)


# with LineCollider

method collide*(t: TileMapCollider, d: LineCollider): bool =
  for tile in t.tiles:
    if tile.collide(d):
      return true
  return false


method collide*(d: LineCollider, t: TileMapCollider): bool {.inline.} =
  collide(t, d)


# with PolyCollider

method collide*(t: TileMapCollider, p: PolyCollider): bool =
  for tile in t.tiles:
    if tile.collide(p):
      return true
  return false


method collide*(p: PolyCollider, t: TileMapCollider): bool {.inline.} =
  collide(t, p)


# with GroupCollider


method collide*(t: TileMapCollider, g: GroupCollider): bool =
  for c in g.list:
    if collide(t, c):
      return true
  return false


method collide*(g: GroupCollider, t: TilemapCollider): bool {.inline.} =
  collide(t, g)


# with TileMapCollider

method collide*(t1, t2: TileMapCollider): bool =
  for tile in t1.tiles:
    if t2.collide(tile):
      return true
  return false

