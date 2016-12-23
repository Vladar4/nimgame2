import
  nimgame2/nimgame,
  nimgame2/entity

type
  Dwarf* = ref object of Entity


proc init*(entity: Dwarf) =
  entity.initEntity()


proc newDwarf*(): Dwarf =
  result = new Dwarf
  result.init()


method update*(physics: Physics, entity: Dwarf, elapsed: float) =
  physics.updatePhysics(entity, elapsed)

