#
#  dxTarRead - 0.91 - public domain
#  no warrenty implied; use at your own risk.
#  authored from 2017 by Dmitry Hrabrov a.k.a. DeXPeriX
#  http://dexperix.net
#
# ORIGINAL CODE LICENSE:
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
  #NameSize    = 100
  SzSize      = 12
  MagicSize   = 5
  Magic       = cast[ptr uint8]("ustar") # Modern GNU tar's magic const
  Char0       = uint8('0')
  Char9       = uint8('9')

# OLD VERSION
#[
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
]#

proc dxTarContents(data: ptr uint8, dataSize: int): seq[tuple[name: cstring, size: int, data: ptr uint8]] =
  result = @[]
  var p, newOffset, size, mul: int

  while true: # "Load" data from tar - just point to passed memory
    inc(p, newOffset) # pointer to current file's data in TAR
    let dataPtr = data + p

    # Check for supported TAR version
    let namePtr = dataPtr + NameOffset
    let magic = p + MagicOffset
    for i in 0..<MagicSize:
      if data[magic + i] != Magic[i]:
        return

    # Calculate size
    size = 0
    mul = 1
    let sizePtr = dataPtr + SizeOffset # size string
    for i in countdown(SzSize - 2, 0):
      if (sizePtr[i] >= Char0) and (sizePtr[i] <= Char9):
        inc(size, int(sizePtr[i] - Char0) * mul)
      mul = mul * 8
    newOffset = (1 + size div BlockSize) * BlockSize # trim by block
    if (size mod BlockSize) > 0: inc(newOffset, BlockSize)

    # add new entry
    if size > 0: # check if not directory
      result.add((cast[cstring](namePtr), size, dataPtr + BlockSize))

    if p + newOffset + BlockSize > dataSize:
      break
  # while true

import zip/zlib, sdl2/sdl

# PUBLIC

type
  TarFile* = object
    data: ptr uint8
    size: int
    contents: seq[tuple[name: cstring, size: int, data: ptr uint8]]


proc contents*(tar: TarFile): seq[string] =
  result = @[]
  for entry in tar.contents:
    result.add($entry.name)


proc close*(tar: var TarFile) =
  if tar.data != nil:
    dealloc(tar.data)
    tar.data = nil
  tar.size = 0
  tar.contents = nil


proc dump(filename: string, buf: var ptr uint8): int =
  ##  Internal file dump procedure.
  ##
  ##  ``Return`` number of bytes read, or `-1` on errors.
  ##
  var f: File
  if not f.open(filename, fmRead):
    return -1
  let size = f.getFileSize().int
  buf = cast[ptr uint8](alloc(size + 1))
  result = f.readBuffer(buf, size)
  f.close()
  if result != size:
    return -1


proc open*(tar: var TarFile, filename: string): bool =
  ##  Open uncompressed TAR archive (eg. "archive.tar").
  ##
  ##  ``Return`` `true` on success, or `false` otherwise
  ##  (or if no usable files found inside).
  if tar.data != nil:
    tar.close()
  # load file
  tar.size = dump(filename, tar.data)
  tar.data[tar.size] = 0
  # read contents
  tar.contents = dxTarContents(tar.data, tar.size)
  return tar.contents.len > 0


proc openz*(tar: var TarFile, filename: string): bool =
  ##  Open compressed TAR archive (e.g. "archive.tar.gz").
  ##
  ##  ``Return`` `true` on success, or `false` otherwise
  ##  (or if no usable files found inside).
  if tar.data != nil:
    tar.close()
  # load file
  var buffer: ptr uint8
  let size = dump(filename, buffer)
  # uncompress
  var decompressed = uncompress(cast[cstring](buffer), size)
  dealloc(buffer)
  tar.size = decompressed.len
  tar.data = cast[ptr uint8](cstring(decompressed))
  # read contents
  tar.contents = dxTarContents(tar.data, tar.size)
  return tar.contents.len > 0


proc index*(tar: TarFile, filename: string): int =
  ##  ``Return`` index of ``filename`` in ``tar`` file, or `-1` if not found.
  ##
  for i in 0..tar.contents.high:
    if tar.contents[i].name == filename:
      return i
  return -1


template exists*(tar: TarFile, filename: string): bool =
  (tar.index(filename) >= 0)


proc read*(tar: TarFile, filename: string): ptr RWops =
  ##  Read ``filename`` from ``tar``
  ##  and return its content as a new ``RWops`` pointer.
  ##
  let idx = tar.index(filename)
  if idx < 0:
    return nil
  return rwFromMem(cast[pointer](tar.contents[idx].data), tar.contents[idx].size)

