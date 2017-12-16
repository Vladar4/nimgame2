#
#  dxTarRead - 0.91 - public domain
#  no warrenty implied; use at your own risk.
#  authored from 2017 by Dmitry Hrabrov a.k.a. DeXPeriX
#  http://dexperix.net
#
# LICENSE:
#     This software is dual-licensed to the public domain and under the following
#     license: you are granted a perpetual, irrevocable license to copy, modify,
#     publish and distribute this file as you see fit.
#

##  Simple utility for reading TAR archives and loading their contents into
##  ``sdl.RWops``. Based on ``dxTarRead`` by Dmitry Hrabrov a.k.a. DeXPeriX.
##
##  Original source link:
##  https://github.com/DeXP/dxTarRead/blob/master/dxTarRead.c
##

# PRIVATE

template `+`[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))

template `[]`[T](p: ptr T, off: int): T =
  (p + off)[]

template `[]=`[T](p: ptr T, off: int, val: T) =
  (p + off)[] = val

const
  NameOffset  = 0
  SizeOffset  = 124
  MagicOffset = 257
  BlockSize   = 512
  NameSize    = 100
  SzSize      = 12
  MagicSize   = 5
  Magic       = "ustar" # Modern GNU tar's magic const

proc dxTarRead(data: ptr uint8, dataSize: int,
               fileName: string, fileSize: var int): ptr uint8 =
  fileSize = 0 #  will be zero if TAR wrong or there is no such file
  var
    size, mul, p, newOffset: int
    found = false

  while true: # "Load" data from tar - just point to passed memory
    var name, sz: ptr uint8
    name = data + (NameOffset + p + newOffset)
    sz = data + (SizeOffset + p + newOffset) # size string
    inc(p, newOffset) # pointer to current file's data in TAR

    for i in 0..<MagicSize: # Check for supported TAR version
      if data[i + MagicOffset + p] != Magic[i].uint8:
        return nil

    size = 0
    mul = 1
    for i in countdown(SzSize - 2, 0):
      if (sz[i] >= '0'.uint8) and (sz[i] <= '9'.uint8):
        inc(size, int(sz[i] - '0'.uint8) * mul)
      mul = mul * 8
    newOffset = (1 + size div BlockSize) * BlockSize # trim by block
    if (size mod BlockSize) > 0: inc(newOffset, BlockSize)
    var i = 0

    # compare file's name with that a user wants
    while (i < NameSize) and
          (fileName[i] != '\0') and
          (name[i].char == fileName[i].char):
      inc(i)

    if (i > 0) and (name[i] == 0) and (fileName[i] == '\0'):
      found = true

    if not ((not found) and (p + newOffset + BlockSize <= dataSize)):
      break
  # while true

  if found:
    fileSize = size
    return data + p + BlockSize
    #  skip header, point to data
  else:
    return nil # No file found in TAR - return nil


import sdl2/sdl

# PUBLIC

type
  TarFile* = object
    data: ptr uint8
    size: int


proc close*(tar: var TarFile) =
  if tar.data != nil:
    dealloc(tar.data)
  tar.data = nil
  tar.size = 0


proc open*(tar: var TarFile, filename: string): bool =
  if tar.data != nil:
    tar.close()
  var f: File
  if not f.open(filename, fmRead):
    return false
  tar.size = f.getFileSize().int
  tar.data = cast[ptr uint8](alloc(tar.size + 1))
  let bytesRead = f.readBuffer(tar.data, tar.size)
  f.close()
  if bytesRead != tar.size:
    tar.close()
    return false
  tar.data[tar.size] = 0


proc read*(tar: TarFile, filename: string): ptr RWops =
  ##  Read ``filename`` from ``tar``
  ##  and return its content as a new ``RWops`` pointer.
  ##
  var size = 0
  var buffer = dxTarRead(tar.data, tar.size, filename, size)
  if buffer == nil:
    return nil
  return rwFromMem(cast[pointer](buffer), size)

