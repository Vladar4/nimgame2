import
  nimgame2/nimgame,
  nimgame2/entity,
  nimgame2/textgraphic,
  nimgame2/texturegraphic,
  nimgame2/bitmapfont,
  nimgame2/input,
  nimgame2/types


type
  JoyPoint* = ref object of Entity
    joy: int
    label: TextGraphic


proc init(jp: JoyPoint, id: int) =
  jp.initEntity()
  jp.joy = id
  jp.graphic = newTextureGraphic("../assets/gfx/target.png")
  jp.centrify()
  jp.pos = game.size / 2
  # label
  let font = newBitmapFont()
  discard font.load("../assets/fnt/default8x16.png", (8, 16))
  jp.label = newTextGraphic(font)
  jp.label.lines = [$id]


proc newJoyPoint*(joystick: int): JoyPoint =
  new result
  result.init(joystick)


method render*(jp: JoyPoint) =
  jp.renderEntity()
  jp.label.draw(
    jp.absPos + jp.center - Coord(jp.label.dim / 2) + (1.0, 1.0),
    jp.absRot,
    jp.absScale,
    jp.center,
    jp.flip)


const Speed = 100

method update*(jp: JoyPoint, elapsed: float) =
  let move = Speed * elapsed / JoyAxis.high.float
  jp.updateEntity(elapsed)
  jp.pos.x += jp.joy.joyAxis(0).float * move
  jp.pos.x = clamp(jp.pos.x, 0.0, game.size.w.float)
  jp.pos.y += jp.joy.joyAxis(1).float * move
  jp.pos.y = clamp(jp.pos.y, 0.0, game.size.h.float)

