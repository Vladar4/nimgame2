import
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/tilemap,
  nimgame2/tween,
  nimgame2/types


const
  Framerate = 1/12
  ScreenOffset*: Coord = (8.0, 0.0)
  Step* = 24.0


type
  Direction* = enum dNone, dDown, dUp, dLeft, dRight

  Dwarf* = ref object of Entity
    tween*: Tween[Dwarf,Coord]
    virtualPos*: tuple[x: int, y: int]
    map*: TileMap


proc initDwarf*(entity: Dwarf, graphic: TextureGraphic, map: TileMap) =
  entity.initEntity()
  entity.tags.add("dwarf")
  entity.graphic = graphic
  entity.initSprite((26, 50))
  discard entity.addAnimation(
    "down", [0, 1, 2, 3, 4, 5], Framerate)
  discard entity.addAnimation(
    "up", [6, 7, 8, 9, 10, 11], Framerate)
  discard entity.addAnimation(
    "left", [12, 13, 14, 15, 16, 17], Framerate)
  discard entity.addAnimation(
    "right", [12, 13, 14, 15, 16, 17], Framerate, Flip.horizontal)
  entity.pos = (44.0, 444.0)
  entity.virtualPos = (1, 18)
  entity.center = (14.0, 38.0)
  entity.map = map
  entity.map.show = (
    x: (entity.virtualPos.x - 2)..(entity.virtualPos.x + 2),
    y: (entity.virtualPos.y - 2)..(entity.virtualPos.y + 2)
  )


proc newDwarf*(graphic: TextureGraphic, map: TileMap): Dwarf =
  result = new Dwarf
  result.initDwarf(graphic, map)


proc actuate(entity: Dwarf, anim: string, movement: Coord) =
  if entity.tween == nil or not entity.tween.playing:
    let
      newPos = entity.pos + movement
      newVirtualPos: tuple[x: int, y: int] =
        (int(newPos.x - ScreenOffset.x) div Step.int,
         int(newPos.y - ScreenOffset.y) div Step.int)

    if entity.map.map[newVirtualPos.y][newVirtualPos.x] > 2:
      return # unpassable

    entity.play(anim, 1)
    entity.tween = newTween[Dwarf,Coord](
      entity,
      proc(t: Dwarf): Coord = t.pos,
      proc(t: Dwarf, val: Coord) = t.pos = val)
    entity.tween.setup(entity.pos, newPos, 0.5, 0)
    entity.virtualPos = newVirtualPos
    entity.tween.play()
    entity.map.show = (
      x: (newVirtualPos.x - 2)..(newVirtualPos.x + 2),
      y: (newVirtualPos.y - 2)..(newVirtualPos.y + 2)
    )


proc move*(entity: Dwarf, direction: Direction) =
  case direction:
  of dDown:   entity.actuate("down", (0.0, Step))
  of dUp:     entity.actuate("up", (0.0, -Step))
  of dRight:  entity.actuate("right", (Step, 0.0))
  of dLeft:   entity.actuate("left", (-Step, 0.0))
  of dNone:   discard

