import
  nimgame2/entity

type
  Poly9* = ref object of Entity
    collidedWith*: seq[string]


proc initPoly9*(entity: Poly9) =
  entity.initEntity()
  entity.tags.add("Poly9")
  entity.centrify
  entity.collider = entity.newPolyCollider((0.0, 0.0),
    [ (-40.0, -50.0),
      (-20.0, -50.0),
      (-30.0,  20.0),
      ( 30.0,  20.0),
      ( 20.0, -50.0),
      ( 40.0, -50.0),
      ( 40.0,  30.0),
      (  0.0,  50.0),
      (-40.0,  30.0)])
  entity.collidedWith = @[]


proc newPoly9*(): Poly9 =
  result = new Poly9
  result.initPoly9()


method update*(entity: Poly9, elapsed: float) =
  entity.updateEntity(elapsed)
  entity.collidedWith = @[]


method onCollide*(entity: Poly9, target: Entity) =
  if target.tags.len > 0:
    entity.collidedWith.add(target.tags[0])

