import
  nimgame2/entity,
  nimgame2/types

type
  Earth* = ref object of Entity


proc initEarth*(entity: Earth, pos: Coord) =
  entity.initEntity()
  entity.pos = pos


proc newEarth*(pos: Coord): Earth =
  result = new Earth
  result.initEarth(pos)

