import
  nimgame2/entity

type
  Earth* = ref object of Entity
    collidedWith*: seq[string]


proc initEarth*(entity: Earth) =
  entity.initEntity()
  entity.tags.add("Earth")
  entity.pos = (0.0, 150.0)
  entity.collidedWith = @[]


proc newEarth*(): Earth =
  result = new Earth
  result.initEarth()


method update*(entity: Earth, elapsed: float) =
  entity.updateEntity(elapsed)
  entity.collidedWith = @[]


method onCollide*(entity: Earth, target: Entity) =
  if target.tags.len > 0:
    entity.collidedWith.add(target.tags[0])

