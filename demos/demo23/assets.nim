import nimgame2/nimgame except init
import
  nimgame2/[
    truetypefont,
    types
  ],
  sdl2/sdl,
  sdl2/sdl_image as img,
  sdl2/sdl_ttf as ttf,
  sdl2/sdl_mixer as mix,
  nimgame2/font as font_module

var
  default_font*: font_module.Font
proc setup*()=
  default_font= newTrueTypeFont()
  if not default_font.TrueTypeFont.load("FSEX300.ttf",36):
    raise newException(SystemError,"could not load default font")
# proc init*(
#   game: Game,
#   w, h: int,
#   title = "Nimgame2",
#   bgColor = sdl.Color(r: 0, g: 0, b: 0, a: 255),
#   windowFlags: uint32 = 0,
#   rendererFlags: uint32 = sdl.RendererAccelerated or sdl.RendererPresentVsync,
#   scaleQuality: range[0..2] = 0,
#   integerScale: bool = false,
#   iconSurface: sdl.Surface = nil,
#   icon: string = "",
#   imageFlags: cint = img.InitPNG,
#   mixerFlags: cint = mix.InitOGG,
#   mixerChannels: int = 32
#   ): bool=
#   result = nimgame.init(
#     game,
#     w,
#     h,
#     title,
#     bgColor,
#     windowFlags,
#     rendererFlags,
#     scaleQuality,
#     integerScale,
#     iconSurface,
#     icon,
#     imageFlags,
#     mixerFlags,
#     mixerChannels
#     )
#   if result:
#     setup()