import
  nimgame2/nimgame,
  nimgame2/entity

type
  Spaceman* = ref object of Entity


proc init*(entity: Spaceman) =
  entity.initEntity()
  entity.pos.x = 200.0
  entity.pos.y = 64.0


proc newSpaceman*(): Spaceman =
  result = new Spaceman
  result.init()

