import
  nimgame2/nimgame,
  nimgame2/collider,
  nimgame2/entity

type
  Poly3* = ref object of Entity
    collidedWith*: seq[string]


proc init*(entity: Poly3) =
  entity.initEntity()
  entity.tags.add("Poly3")
  entity.collider = entity.newPolyCollider((0.0, 0.0),
    [ (0.0,   0.0),
      (50.0,  0.0),
      (25.0,  35.0)])
  entity.collidedWith = @[]


proc newPoly3*(): Poly3 =
  result = new Poly3
  result.init()


method update*(entity: Poly3, elapsed: float) =
  entity.updateEntity(elapsed)
  entity.collidedWith = @[]


method onCollide*(entity: Poly3, target: Entity) =
  if target.tags.len > 0:
    entity.collidedWith.add(target.tags[0])

