import
  sdl2/sdl,
  random,
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/graphic,
  nimgame2/scene,
  nimgame2/types

type
  Spaceman* = ref object of Entity
    scene*: Scene


proc init*(entity: Spaceman, sc: Scene, gr: Graphic, lo: Logic) =
  entity.initEntity()
  entity.scene = sc
  entity.graphic = gr
  entity.logic = lo
  entity.pos.x = random(game.dim.w - entity.graphic.w).float
  entity.pos.y = random(game.dim.h - entity.graphic.h).float
  entity.vel.x = random(10.0..100.0) * random([-1, 1]).float
  entity.vel.y = random(10.0..100.0) * random([-1, 1]).float
  entity.rot = random(0.0..360.0)
  entity.rotVel = random(10.0..60.0) * random([-1, 1]).float


proc newSpaceman*(sc: Scene, gr: Graphic, lo: Logic): Spaceman =
  result = new Spaceman
  result.init(sc, gr, lo)


proc renderSpaceman*(entity: Spaceman, renderer: sdl.Renderer) =
  entity.graphic.drawEx(game.renderer,
                        entity.pos,
                        entity.rot,
                        entity.rotCentered,
                        entity.rotAnchor,
                        entity.flip)


method render*(entity: Spaceman, renderer: sdl.Renderer) =
  renderSpaceman(entity, renderer)


method update*(entity: Spaceman, elapsed: float) =
  entity.updateEntity(elapsed)

