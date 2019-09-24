import
  nimgame2/entity

type
  Poly2* = ref object of Entity
    collidedWith*: seq[string]


proc initPoly2*(entity: Poly2) =
  entity.initEntity()
  entity.tags.add("Poly2")
  entity.collider = entity.newPolyCollider((0.0, 0.0),
    [ (0.0,   0.0),
      (50.0,  0.0)])
  entity.collidedWith = @[]


proc newPoly2*(): Poly2 =
  result = new Poly2
  result.initPoly2()


method update*(entity: Poly2, elapsed: float) =
  entity.updateEntity(elapsed)
  entity.collidedWith = @[]


method onCollide*(entity: Poly2, target: Entity) =
  if target.tags.len > 0:
    entity.collidedWith.add(target.tags[0])

