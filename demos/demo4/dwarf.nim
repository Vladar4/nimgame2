import
  nimgame2/nimgame,
  nimgame2/entity

type
  Dwarf* = ref object of Entity


proc init*(entity: Dwarf) =
  entity.initEntity()
  entity.centrify()
  entity.physics = defaultPhysics


proc newDwarf*(): Dwarf =
  result = new Dwarf
  result.init()

