import
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/types

type
  Earth* = ref object of Entity


proc init*(entity: Earth, pos: Coord) =
  entity.initEntity()
  entity.pos = pos


proc newEarth*(pos: Coord): Earth =
  result = new Earth
  result.init(pos)

