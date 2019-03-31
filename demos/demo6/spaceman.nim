import
  nimgame2/nimgame,
  nimgame2/entity

type
  Spaceman* = ref object of Entity


proc initSpaceman*(entity: Spaceman) =
  entity.initEntity()
  entity.tags.add("Spaceman")
  entity.pos = (200.0, 0.0)


proc newSpaceman*(): Spaceman =
  result = new Spaceman
  result.initSpaceman()


method update*(entity: Spaceman, elapsed: float) =
  entity.updateEntity(elapsed)

