import
  nimgame2/entity

type
  Earth* = ref object of Entity


proc initEarth*(entity: Earth) =
  entity.initEntity()
  entity.tags.add("Earth")
  entity.pos = (8.0, 64.0)


proc newEarth*(): Earth =
  result = new Earth
  result.initEarth()

