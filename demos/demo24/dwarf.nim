import
  nimgame2/entity,
  nimgame2/graphicgroup,
  nimgame2/outline,
  nimgame2/surfacegraphic,
  nimgame2/types,
  nimgame2/utils


type
  Dwarf* = ref object of Entity


const Framerate = 1/12


proc initDwarf*(entity: Dwarf) =
  entity.initEntity()
  entity.physics = defaultPhysics

  # GraphicGroup
  var
    gg = newGraphicGroup()
  gg.list.add(
    (newSurfaceGraphic("../assets/gfx/dwarf.png"), (0,0)))
  gg.list.add(
    (newOutline(color=ColorWhite,
                source=SurfaceGraphic(gg.list[0].graphic).surface),
    (-1, -1)))

  entity.graphic = gg
  entity.centrify()

  # sprite
  entity.initSprite((26, 50))
  discard entity.addAnimation("all", toSeq(0..17), Framerate)


proc newDwarf*(): Dwarf =
  result = new Dwarf
  result.initDwarf()

