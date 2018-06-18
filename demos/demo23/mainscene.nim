import
  nimgame2 / [
    truetypefont, textgraphic, entity, 
    nimgame, scene, types, 
    graphic, input, settings],
  nimgame2 / gui / widget,
  private/[
    circle_graphic, 
    frame]

type
  MainScene* = ref object of Scene
    font*: TrueTypeFont
proc newCircleEntity*(): Entity =
  var cgraphic = newCircleGraphic()
  cgraphic.radius = 4.0
  cgraphic.draw_border = false

  result = newEntity()
  result.graphic = cgraphic
  result.centrify()

proc createRotScaleTestEnts*(scene: MainScene, text: string; pos: var Coord; rot: Angle = 0.0; scale: Scale = 1.0) =
  var
    textEnt = newEntity()
    textgraphic = newTextGraphic(scene.font)
  scene.add(textEnt)
  textEnt.graphic = textgraphic

  textgraphic.setText text

  textEnt.scale = scale
  textEnt.pos = pos + (textEnt.bottomleft * textEnt.absScale)
  textEnt.center += textEnt.bottomleft
  echo textEnt.pos
  # Want rel_pos before rotation
  pos.y = (textEnt.transform * textEnt.bottomleft).y
  textEnt.rot = rot * 90.0
  for p in textEnt.world_corners.items():
    var cent = newCircleEntity()
    scene.add(cent)
    cent.pos = p
  var frameEnt = newGuiWidget()
  scene.add(frameEnt)
  var fGraphic = newFrameGraphic()
  frameEnt.graphic = fGraphic
  fGraphic.draw_filled = false
  fGraphic.border_color = ColorRed
  fGraphic.rect.x = textEnt.topleft.x.cint
  fGraphic.rect.y = textEnt.topleft.y.cint
  fGraphic.rect.w = textEnt.dim.w.cint
  fGraphic.rect.h = textEnt.dim.h.cint
  frameEnt.logic = proc (entity: Entity; elapsed: float) =
    let color =
      if entity.GuiWidget.state.isFocused: ColorOrange
      else: ColorGreen
    entity.graphic.FrameGraphic.border_color = color


  frameEnt.center = textEnt.center
  frameEnt.pos = textEnt.pos
  frameEnt.rot = textEnt.rot
  frameEnt.scale = textEnt.scale
  var corners = newseq[Coord]()
  for c in frameEnt.corners:
    corners.add(c)
  frameEnt.collider = frameEnt.newPolyCollider(frameEnt.pos, corners)

    
proc init*(scene: MainScene)=
  scene.Scene.init()
  scene.font = newTrueTypeFont()
  discard scene.font.load("../assets/fnt/FSEX300.ttf", 32)

  var rel_pos: Coord = (200.0, 0.0)
  for scale in [0.8, 0.3, 0.4, 0.6, 0.7, 0.2]:
    createRotScaleTestEnts(scene, "Scale Test", rel_pos, scale = scale)

  for f in [0.8, 0.3, 0.4, 0.6, 0.7, 0.2]:
    createRotScaleTestEnts(scene, "Rot Scale Test", rel_pos, rot = f, scale = f)

  rel_pos = (400.0, 0.0)
  for rot in [0.8, 0.3, 0.4, 0.6, 0.7, 0.2]:
    createRotScaleTestEnts(scene, "Rot Test", rel_pos, rot = rot)

proc newMainScene*(): MainScene =
  new result
  result.init()