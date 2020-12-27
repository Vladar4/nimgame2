#
#    Copyright (c) 2001 Guido Draheim <guidod@gmx.de>
#    Use freely under the restrictions of the ZLIB License
#

##  You should be able to drop it in the place of a ``sdl.rwFromFile()``.
##  Then go to `X/share/myapp` and do
##  ```cd graphics && zip -9r ../graphics.zip .```
##  and rename the `graphics/` subfolder - and still all your files
##  are found: a filepath like `X/shared/graphics/game/greetings.bmp`
##  will open `X/shared/graphics.zip` and return the zipped file
##  `game/greetings.bmp` in the zip-archive (for reading that is).
##
##  See original code at http://zziplib.sourceforge.net/zzip-sdl-rwops.html
##
##  ``Note:`` zzip dynamic library should be available in the system.

import
  sdl2/sdl, zip/zzip


# PRIVATE

template rwopsZzipData(context: ptr RWops): untyped =
  (context.mem.unknown.data1)

template rwopsZzipFile(context: ptr RWops): untyped =
  cast[ptr Zzip_File]((context.mem.unknown.data1))

proc zzipSeek*(context: ptr RWops,
               offset: int64, whence: cint): int64 {.cdecl.} =
  return zzipSeek(rwopsZzipFile(context), offset.int, whence)

proc zzipRead*(context: ptr RWops,
               buf: pointer, size: csize, maxnum: csize): csize {.cdecl.} =
  return zzipRead(rwops_Zzip_File(context), buf, size * maxnum) div size

proc zzipWrite*(context: ptr RWops,
                buf: pointer; size: csize, num: csize): csize {.cdecl.} =
  return 0 # ignored

proc zzipClose*(context: ptr RWops): cint {.cdecl.} =
  if context == nil:
    return 0
  zzipClose(rwops_Zzip_File(context))
  freeRW(context)
  return 0


# PUBLIC

proc rwFromZZip*(file, mode: string = "r"): ptr RWops =
  var f: ptr ZZipFile
  if not ('r' in mode): return rwFromFile(file, mode)
  f = zzipFopen(file, mode)
  if f == nil:
    return nil
  result = allocRW()
  if result == nil:
    zzipClose(f)
    raise newException(OutOfMemDefect, "allocRW(): out of memory")
  rwopsZzipData(result) = f
  result.read = zzipRead
  result.write = zzipWrite
  result.seek = zzipSeek
  result.close = zzipClose

