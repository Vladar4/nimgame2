Nimgame 2 code formatting style
===============================

In general, follow [NEP1](https://nim-lang.org/docs/nep1.html) if it doesn't contradict this document.


Line Spacing
------------
* two empty lines before and one empty line after the header-comment;
* two empty lines between blocks (such as `const`, `type`, `proc`, etc.);
* one empty line to separate segments inside these blocks if needed;
* one empty line at the end of files.


Comments
--------

* if there is more than one type declared in one module, their procedures should be separated with header-comments:
  ```
  #==========#
  # SomeType #
  #==========#
  ```
* documentation comments are always offset by one indentation level inside their procedures, have two spaces before their text, and one empty comment line to separate it from the code below.
  ```
  proc someProc() =
    ##  Documentation comment.
    ##
    var someVar
    ...
  ```


Naming
------
* types and constants in PascalCase;
* all other identifiers in camelCase;
* if an object is a first argument of a procedure, generally it should be named after its type, e.g.:
  ```
  proc foo(bar: Bar, val: int): int =
  ```


Objects
-------
* private and public fields should be separated with comments if possible;
* `ref object` types should have the following initialization scheme:
  ```
  type SomeType = ref object of SomeParent
    someValue*: int


  proc initSomeType*(someType: SomeType) =
    someType.initSomeParent() # don't forget the parent initialization
    SomeType.someValue = 0
    ...


  proc newSomeType*(): SomeType =
    result = new SomeType
    result.initSomeType()
  ```
* types that are inherited from the `Entity` type should follow the following update scheme:
  ```
  type
    SomeEntity = ref object of Entity


  proc updateSomeEntity*(someEntity: SomeEntiy, elapsed: float) =
    someEntity.updateEntity(elapsed) # don't forget the parent update
    ...


  method update*(someEntity: SomeEntiy, elapsed: float) =
    updateSomeEntity(someEntity, elapsed)
  ```


Code
----
* don't forget proper spaces between elements;
* procedural arguments are separated by commas, e.g.:
  ```
  proc someProc(arg1: int, arg2, arg3: float): float =
  ```
* if there are a lot of arguments, they could be brought to a new line and indented by two levels for the sake of readability, e.g.:
  ```
  proc someLongAndComplexProcedure(
      arg1, arg2, arg3, arg4: int
      arg5, arg6, arg7, arg8: float) =
    ## Documentation
    ##
    ...
  ```


Example
-------
  ```
  # Header

  type
    SomeType1 = object
      # Private
      fHidden: int
      # Public
      value*: int

    SomeType2 = object
      a, b*: float


  const
    SomeConst1 = 42


  proc someProc*(arg1: int): int =
    ...


  #===========#
  # SomeType1 #
  #===========#

  proc someProc1*(someType1: SomeType1, a, b: int) =
    ...


  #===========#
  # SomeType2 #
  #===========#

  ...

  ```

