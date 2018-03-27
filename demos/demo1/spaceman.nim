import
  random,
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/graphic,
  nimgame2/scene,
  nimgame2/types,
  nimgame2/utils

type
  Spaceman* = ref object of Entity
    scene*: Scene


proc init*(entity: Spaceman, s: Scene, g: Graphic, p: PhysicsProc) =
  entity.initEntity()
  entity.scene = s
  entity.graphic = g
  entity.physics = p
  entity.pos.x = rand(game.size.w).float
  entity.pos.y = rand(game.size.h).float
  entity.vel.x = rand(10.0..100.0) * randSign().float
  entity.vel.y = rand(10.0..100.0) * randSign().float
  entity.centrify()
  entity.rot = rand(360.0)
  entity.rotVel = rand(10.0..60.0) * randSign().float


proc newSpaceman*(s: Scene, g: Graphic, p: PhysicsProc): Spaceman =
  result = new Spaceman
  result.init(s, g, p)

