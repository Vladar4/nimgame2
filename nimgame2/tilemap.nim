# nimgame2/tilemap.nim
# Copyright (c) 2016-2019 Vladimir Arabadzhi (Vladar)
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
  entity, graphic, types, utils


const
  DefaultTileScale*: Scale = 1.02


type
  TileShow* = tuple[x: Slice[int], y: Slice[int]]

  TileMap* = ref object of Entity
    # Public
    map*: seq[seq[int]] ##  Two-dimensional sequence of tile indexes (y, x)
    fShow: TileShow     ##  Slice of what part of map to show
    hidden*: seq[int]   ##  The list of tile indexes to not render
    passable*: seq[int] ##  The list of tile indexes without colliders
    onlyReachableColliders*: bool ##  Do not create colliders \
                                  ##  for unreachable tiles
    tileScale*: Scale   ##  \
      ##  The scaling of individual tiles, mostly used for gap removal. \
      ##  Increase on scales vastly different from `1.0`. \
      ##  Set to `1.0` if your map isn't rotating or scaling.

  TileCollider* = ref object of BoxCollider
    # Public
    value*: int       ##  Tile kind value
    index*: CoordInt  ##  Map coordinates

  TileMapCollider* = ref object of Collider  ## Collider to use with TileMap
    # Private
    map: TileMap
    tiles: seq[seq[TileCollider]] ##  Two-dimensional sequence of colliders \
                                  ##  (y, x)


#=========#
# TileMap #
#=========#

proc initTileMap*(tilemap: TileMap, scaleFix = false) =
  ##  TileMap initialization.
  ##
  ##  ``scaleFix``  set ``tileScale`` to ``DefaultTileScale`` if `true`,
  ##  or to `1.0` otherwise.
  ##
  tilemap.initEntity()
  tilemap.map = @[]
  tilemap.fShow = (0..0, 0..0)
  tilemap.hidden = @[]
  tilemap.passable = @[]
  tilemap.tileScale = if scaleFix: DefaultTileScale else: 1.0


template init*(tilemap: TileMap, scaleFix = false) {.deprecated: "Use initTileMap() instead".} =
  initTileMap(tilemap, scaleFix)


proc newTileMap*(scaleFix = false): TileMap =
  ##  Create a new TileMap.
  ##
  ##  ``scaleFix``  set ``tileScale`` to ``DefaultTileScale`` if `true`,
  ##  or to `1.0` otherwise.
  ##
  result = new TileMap
  result.initTileMap(scaleFix)


proc show*(tilemap: TileMap): TileShow {.inline.} =
  ##  ``Return`` a currently shown slices of tiles.
  ##
  return tilemap.fShow


proc `show=`*(tilemap: TileMap, val: TileShow) =
  ##  Set new values for the shown slices of tiles.
  ##
  if tilemap.fShow == val:
    return
  var show: TileShow
  show.y.a = if val.y.a < 0: 0 else: val.y.a
  show.y.b = if val.y.b > tilemap.map.high: tilemap.map.high else: val.y.b
  show.x.a = if val.x.a < 0: 0 else: val.x.a
  show.x.b = if val.x.b > tilemap.map[0].high: tilemap.map[0].high else: val.x.b
  tilemap.fShow = show


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
  ##  Iterate through tiles with a specific ``value``.
  ##
  for y in 0..tilemap.map.high:
    for x in 0..tilemap.map[y].high:
      if tilemap.map[y][x] == value:
        yield (x, y)


proc firstTileIndex*(tilemap: TileMap, value: int): CoordInt =
  ##  ``Return`` the first tile index with a specific ``value``.
  ##
  for i in tilemap.tileIndex(value):
    return i


proc tileIndex*(tilemap: TileMap, pos: Coord): CoordInt =
  ##  ``Return`` the tile map index of a tile
  ##  that is located at the given screen position.
  ##
  let
    dim: Coord = tilemap.sprite.dim * tilemap.absScale
    offset: Coord = pos - tilemap.pos
  result = (
    int(offset.x / dim.x),
    int(offset.y / dim.y))


proc tilePos*(tilemap: TileMap, index: CoordInt): Coord =
  ##  ``Return`` screen position of a tile with the given tile map index.
  ##
  let
    dim: Coord = tilemap.sprite.dim * tilemap.absScale
    offset: Coord =
      - (tilemap.tileScale - 1) * tilemap.sprite.dim * tilemap.absScale / 2.0
  result = (
    index.x.float * dim.x + offset.x,
    index.y.float * dim.y + offset.y)


template tile*(tilemap: TileMap, index: CoordInt): var int =
  ##  Direct access to a single tile value.
  ##
  tilemap.map[index.y][index.x]


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

proc initTileCollider*(
    t: TileCollider,
    parent: TileMap, pos: Coord = (0, 0), dim: Dim = (0, 0),
    value: int, index: CoordInt) =
  t.initBoxCollider(parent, pos, dim)
  t.value = value
  t.index = index


template init*(t: TileCollider,
               parent: TileMap, pos: Coord = (0, 0), dim: Dim = (0, 0),
               value: int, index: CoordInt) {.deprecated: "Use initTileCollider() instead".} =
  initTileCollider(t, parent, pos, dim, value, index)


proc newTileCollider*(parent: TileMap, pos: Coord = (0, 0), dim: Dim = (0, 0),
                      value: int, index: CoordInt): TileCollider =
  new result
  result.initTileCollider(parent, pos, dim, value, index)


#=================#
# TileMapCollider #
#=================#

proc initTileMapCollider*(
    t: TileMapCollider,
    parent: TileMap, pos: Coord = (0, 0), dim: Dim = (0, 0)) =
  t.initCollider(parent, pos)
  t.tiles = @[]

  parent.updateShow()

  let
    scale = parent.tileScale
    spriteDim: Coord = parent.sprite.dim
    dim: Coord = spriteDim * scale
    offset: Coord = spriteDim / 2.0 - parent.center

  var
    position: Coord
    neighbors: seq[seq[int]]

  if parent.onlyReachableColliders and parent.map.len > 0:
    let
      lenY = parent.map.len
      highY = parent.map.high-1
      lenX = parent.map[0].len
      highX = parent.map[0].high-1

    # count neighbors
    newSeq(neighbors, lenY)
    for y in 1..highY:
      newSeq(neighbors[y], lenX)
      for x in 1..highX:
        if parent.map[y-1][x] notin parent.passable:
          inc neighbors[y][x]
        if parent.map[y+1][x] notin parent.passable:
          inc neighbors[y][x]
        if parent.map[y][x-1] notin parent.passable:
          inc neighbors[y][x]
        if parent.map[y][x+1] notin parent.passable:
          inc neighbors[y][x]
    newSeq(neighbors[0], lenX)
    newSeq(neighbors[^1], lenX)

  for y in 0..parent.map.high:
    position.y = dim.y * y.float / scale + offset.y
    t.tiles.add @[]

    for x in 0..parent.map[y].high:
      t.tiles[y].add nil
      if parent.onlyReachableColliders:
        if neighbors[y][x] > 3:
          continue
      if parent.map[y][x] notin parent.passable:
        position.x = dim.x * x.float / scale + offset.x
        t.tiles[y][x] = newTileCollider(
          parent, position, dim, parent.map[y][x], (x, y))


template init*(t: TileMapCollider, parent: TileMap, pos: Coord = (0, 0),
               dim: Dim = (0, 0)) {.deprecated: "Use initTileMapCollider() instead".} =
  initTileMapCollider(t, parent, pos, dim)


proc newTileMapCollider*(parent: TileMap,
                         pos: Coord = (0, 0),
                         dim: Dim = (0, 0)): TileMapCollider =
  ##  Create a ``TileMapCollider`` for the ``parent`` ``TileMap``.
  ##
  ##  Most of the times you should use ``createCollider()`` instead.
  ##
  ##  ``pos`` Collider's relative position. Usually `(0, 0)`.
  ##
  ##  ``dim`` Tile dimensions.
  ##
  result = new TileMapCollider
  result.initTileMapCollider(parent, pos, dim)


iterator tileColliders*(t: TilemapCollider): TileCollider =
  ##  Iterate through all tile colliders of ``t`` TilemapCollider.
  ##
  for y in t.map.show.y:
    for x in t.map.show.x:
      let tile = t.tiles[y][x]
      if not (tile == nil):
        yield tile


method render*(t: TileMapCollider) =
  for tile in t.tileColliders:
    tile.render()
  t.renderCollider()


proc createCollider*(tilemap: TileMap) =
  ##  Initialize a collider for the ``tilemap``.
  ##
  let collider = newTileMapCollider(tilemap, (0, 0), tilemap.sprite.dim)
  collider.map = tilemap
  tilemap.collider = collider


template initCollider*(tilemap: TileMap) {.deprecated: "Use createCollider() instead".} =
  createCollider(tilemap)


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
  for tile in t.tileColliders:
    if tile.collide(a):
      result.add(tile)
      if first: break
  result


# with Coord

method collide*(t: TileMapCollider, pos: Coord): bool =
  for tile in t.tileColliders:
    if tile.collide(pos):
      return true
  return false


# with Collider

method collide*(t: TileMapCollider, a: Collider): bool =
  for tile in t.tileColliders:
    if tile.collide(a):
      return true
  return false


method collide*(a: Collider, t: TileMapCollider): bool {.inline.} =
  collide(t, a)


# with BoxCollider

method collide*(t: TileMapCollider, b: BoxCollider): bool =
  for tile in t.tileColliders:
    if tile.collide(b):
      return true
  return false


method collide*(b: BoxCollider, t: TileMapCollider): bool {.inline.} =
  collide(t, b)


# with CircleCollider

method collide*(t: TileMapCollider, c: CircleCollider): bool =
  for tile in t.tileColliders:
    if tile.collide(c):
      return true
  return false


method collide*(c: CircleCollider, t: TileMapCollider): bool {.inline.} =
  collide(t, c)


# with LineCollider

method collide*(t: TileMapCollider, d: LineCollider): bool =
  for tile in t.tileColliders:
    if tile.collide(d):
      return true
  return false


method collide*(d: LineCollider, t: TileMapCollider): bool {.inline.} =
  collide(t, d)


# with PolyCollider

method collide*(t: TileMapCollider, p: PolyCollider): bool =
  for tile in t.tileColliders:
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
  for tile in t1.tileColliders:
    if t2.collide(tile):
      return true
  return false

