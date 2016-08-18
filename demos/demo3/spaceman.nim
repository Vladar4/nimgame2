import
  nimgame2/nimgame,
  nimgame2/entity

type
  Spaceman* = ref object of Entity


proc init*(entity: Spaceman) =
  entity.initEntity()
  entity.pos.x = game.size.w.float / 2 - 50.0
  entity.pos.y = game.size.h.float / 2 - 80.0
  entity.drg.x = 10.0
  entity.drg.y = 10.0


proc newSpaceman*(): Spaceman =
  result = new Spaceman
  result.init()

