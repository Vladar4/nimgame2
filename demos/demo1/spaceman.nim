import
  random,
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/graphic,
  nimgame2/scene,
  nimgame2/types

type
  Spaceman* = ref object of Entity
    scene*: Scene


proc init*(entity: Spaceman, s: Scene, g: Graphic, p: Physics) =
  entity.initEntity()
  entity.scene = s
  entity.graphic = g
  entity.physics = p
  entity.pos.x = random(game.size.w).float
  entity.pos.y = random(game.size.h).float
  entity.vel.x = random(10.0..100.0) * random([-1, 1]).float
  entity.vel.y = random(10.0..100.0) * random([-1, 1]).float
  entity.center = (g.w / 2, g.h / 2)
  entity.renderEx = true
  entity.rot = random(0.0..360.0)
  entity.rotVel = random(10.0..60.0) * random([-1, 1]).float


proc newSpaceman*(s: Scene, g: Graphic, p: Physics): Spaceman =
  result = new Spaceman
  result.init(s, g, p)

