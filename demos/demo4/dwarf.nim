import
  nimgame2/entity,
  nimgame2/texturegraphic,
  nimgame2/types

type
  Dwarf* = ref object of Entity

const Framerate = 1/12


proc initDwarf*(entity: Dwarf) =
  entity.initEntity()
  entity.graphic = newTextureGraphic()
  discard TextureGraphic(entity.graphic).load("../assets/gfx/dwarf.png")
  entity.physics = defaultPhysics
  entity.centrify()
  entity.initSprite((26, 50))
  discard entity.addAnimation(
    "down", [0, 1, 2, 3, 4, 5], Framerate)
  discard entity.addAnimation(
    "up", [6, 7, 8, 9, 10, 11], Framerate)
  discard entity.addAnimation(
    "left", [12, 13, 14, 15, 16, 17], Framerate)
  discard entity.addAnimation(
    "right", [12, 13, 14, 15, 16, 17], Framerate, Flip.horizontal)


proc newDwarf*(): Dwarf =
  result = new Dwarf
  result.initDwarf()

