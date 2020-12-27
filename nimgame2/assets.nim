# nimgame2/assets.nim
# Copyright (c) 2016-2018 Vladimir Arabadzhi (Vladar)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# vladar4@gmail.com
# https://github.com/Vladar4

import
  os, math, tables


export
  tables


type
  Assets*[T] = OrderedTableRef[string, T]


proc load[T](assets: Assets[T],
             files: openarray[string],
             init: proc(file: string):T) =
  assets[] = initOrderedTable[string, T](nextPowerOfTwo(files.len))
  for i in files:
    let
      name = i.splitFile.name
      data = init(i)
    #assets.add(name, data) # pre-nim1.4
    assets[name] = data


proc load[T](assets: Assets[T],
             dir: string,
             init: proc(file: string): T) =
  var files: seq[string] = @[]
  for i in walkDir(dir):
    if i.kind == pcFile:
      files.add(i.path)
  assets.load(files, init)


iterator loadIter*[T](assets: Assets[T],
                      files: openarray[string],
                      init: proc(file: string):T): int =
  ##  Iterative loader.
  ##
  ##  ``Yields`` the count of files loaded so far.
  var count = 0
  assets[] = initOrderedTable[string, T](nextPowerOfTwo(files.len))
  for i in files:
    let
      name = i.splitFile.name
      data = init(i)
    #assets.add(name, data) # pre-nim1.4
    assets[name] = data
    inc count
    yield count


iterator loadIter*[T](assets: Assets[T],
                      dir: string,
                      init: proc(file: string): T): int =
  ##  Iterative loader.
  ##
  ##  ``Yields`` the count of files loaded so far.
  var files: seq[string] = @[]
  for i in walkDir(dir):
    if i.kind == pcFile:
      files.add(i.path)
  for count in assets.loadIter(files, init):
    yield count


proc newAssets*[T](files: openarray[string], init: proc(file: string): T): Assets[T] =
  ##  Create a new assets collection.
  ##
  ##  ``files`` an array of target files.
  ##
  ##  ``init`` ``T``'s init/load procedure.
  ##
  new result
  result.load(files, init)


proc newAssets*[T](dir: string, init: proc(file: string): T): Assets[T] =
  ##  Create a new assets collection.
  ##
  ##  ``dir`` target directory.
  ##
  ##  ``init`` ``T``'s init/load procedure.
  ##
  new result
  result.load(dir, init)

