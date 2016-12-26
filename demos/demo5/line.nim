import
  nimgame2/nimgame,
  nimgame2/entity

type
  Line* = ref object of Entity
    collidedWith*: seq[string]


proc init*(entity: Line) =
  entity.initEntity()
  entity.tags.add("Line")
  entity.pos = (50.0, 420.0)
  entity.center = (50.0, 0.0)
  entity.collidedWith = @[]


proc newLine*(): Line =
  result = new Line
  result.init()


method update*(entity: Line, elapsed: float) =
  entity.updateEntity(elapsed)
  entity.collidedWith = @[]


method onCollide*(entity: Line, target: Entity) =
  if target.tags.len > 0:
    entity.collidedWith.add(target.tags[0])

