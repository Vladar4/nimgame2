import
  nimgame2/entity

type
  Earth* = ref object of Entity


proc initEarth*(entity: Earth) =
  entity.initEntity()
  entity.pos.x = 128.0
  entity.pos.y = 96.0


proc newEarth*(): Earth =
  result = new Earth
  result.initEarth()

