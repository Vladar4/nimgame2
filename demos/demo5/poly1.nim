import
  nimgame2/entity

type
  Poly1* = ref object of Entity
    collidedWith*: seq[string]


proc initPoly1*(entity: Poly1) =
  entity.initEntity()
  entity.tags.add("Poly1")
  entity.collider = entity.newPolyCollider((0.0, 0.0),
    [ (0.0,   0.0)])
  entity.collidedWith = @[]


proc newPoly1*(): Poly1 =
  result = new Poly1
  result.initPoly1()


method update*(entity: Poly1, elapsed: float) =
  entity.updateEntity(elapsed)
  entity.collidedWith = @[]


method onCollide*(entity: Poly1, target: Entity) =
  if target.tags.len > 0:
    entity.collidedWith.add(target.tags[0])

