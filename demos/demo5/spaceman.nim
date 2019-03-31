import
  nimgame2/nimgame,
  nimgame2/entity

type
  Spaceman* = ref object of Entity
    collidedWith*: seq[string]


proc initSpaceman*(entity: Spaceman) =
  entity.initEntity()
  entity.tags.add("Spaceman")
  entity.pos = (450.0, 100.0)
  entity.collidedWith = @[]


proc newSpaceman*(): Spaceman =
  result = new Spaceman
  result.initSpaceman()


method update*(entity: Spaceman, elapsed: float) =
  entity.updateEntity(elapsed)
  entity.collidedWith = @[]


method onCollide*(entity: Spaceman, target: Entity) =
  if target.tags.len > 0:
    entity.collidedWith.add(target.tags[0])

