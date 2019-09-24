import
  nimgame2/entity

type
  Line* = ref object of Entity
    collidedWith*: seq[string]


proc initLine*(entity: Line) =
  entity.initEntity()
  entity.tags.add("Line")
  entity.collidedWith = @[]


proc newLine*(): Line =
  result = new Line
  result.initLine()


method update*(entity: Line, elapsed: float) =
  entity.updateEntity(elapsed)
  entity.collidedWith = @[]


method onCollide*(entity: Line, target: Entity) =
  if target.tags.len > 0:
    entity.collidedWith.add(target.tags[0])

