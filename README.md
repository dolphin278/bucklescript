# [BuckleScript](http://bloomberg.github.io/bucklescript/) 

[![NPM](https://nodei.co/npm/bs-platform.png?compact=true)](https://nodei.co/npm/bs-platform/)

[![Build Status](https://travis-ci.org/bloomberg/bucklescript.svg?branch=master)](https://travis-ci.org/bloomberg/bucklescript)
[![Coverage Status](https://coveralls.io/repos/github/bloomberg/bucklescript/badge.svg?branch=master)](https://coveralls.io/github/bloomberg/bucklescript?branch=master)

## Introduction
BuckleScript is a JavaScript backend for [the OCaml compiler](https://ocaml.org/).

You can try
[BuckleScript in the browser](http://bloomberg.github.io/bucklescript/js-demo/),
edit the code on the left panel and see the generated JS on the right
panel instantly.

Users of BuckleScript can write type-safe, high performance OCaml code,
and deploy the generated JavaScript in any platform with a JavaScript
execution engine.

Each OCaml module is mapped to a corresponding JavaScript module, and names are preserved so that:

1. The stacktrace is preserved, the generated code is debuggable with or without sourcemap.
2. Modules generated by BuckleScript can be used directly from other JavaScript code. For example, you can call the `List.length` function from the OCaml standard library `List` module from JavaScript.

### A simple example

``` ocaml
let sum n =
    let v  = ref 0 in
    for i = 0 to n do
       v := !v + i
    done;
    !v
```

BuckleScript generates code similar to this:

``` js
function sum(n) {
  var v = 0;
  for(var i = 0; i<= n; ++i){
    v += i;
  }
  return v;
}
```

As you can see, there is no name mangling in the generated code, so if this module is called `M`,
`M.sum()` is directly callable from other JavaScript code.




## Disclaimer

This project has been released to exchange ideas and collect feedback from the OCaml and JavaScript communities.

It is in an *pre-alpha* stage and we encourage you to try it and share
your feedback.

## Documentation

See http://bloomberg.github.io/bucklescript/, if you want to contribute documentation, the source is [here](./docs)

## Build


### Linux and Mac OSX

#### Build from package manager

1. opam switch (Recommended, but optional)
   
  ```
  opam switch 4.02.3+buckle-1
  ```
  With this switch, you can install all OCaml tools which is compatible with BuckleScript
  
2. npm install

  ```
  npm install  bs-platform
  ```
   

#### Build from source

1. Clone the bucklescript repo

  ```sh
  git clone https://github.com/bloomberg/bucklescript.git --recursive
  ```

  Note that you have to clone this project with `--recursive` option,
  as the core OCaml compiler is brought into your clone as a Git `submodule`.


2. Build the patched OCaml Compiler

  ```sh
  cd ./ocaml
  git checkout master
  ./configure -prefix `pwd`
  make world.opt
  make install
  ```

  The patched compiler is installed locally into your `$(pwd)/bin`
  directory; check if `ocamlc.opt` and `ocamlopt.opt` are there, then temporarily
  add them into your `$(PATH)` (eg - `PATH=$(pwd)/bin:$PATH`).

3. Build BuckleScript Compiler

  Assume that you have `ocamlopt.opt`(the one which we just built) in the `PATH`

  ```sh
  cd ./jscomp
  make world
  ```

  Now you have a binary called `bsc` under `jscomp/bin` directory,
  put it in your `PATH`. You could also set an environment variable
  pointing to the stdlib, like `BSC_LIB=/path/to/jscomp/stdlib`


  Note by default, `bsc` will generate `commonjs` modules, you can
  override such behavior by picking up your own module system:


  ```sh
  MODULE_FLAGS='-js-module amdjs' make world
  MODULE_FLAGS='-js-module commonjs' make world
  MODULE_FLAGS='-js-module goog:buckle' make world
  ```
  
4. Test

  In a separate directory, create a file called `hello.ml`:

  ```sh
  mkdir tmp
  cd tmp
  echo 'print_endline "hello world";;' >hello.ml
  ```

  Then compile it with `bsc`.
  ```sh
  bsc -I . -I $BSC_LIB -c hello.ml
  ```

  It should generate a file called `hello.js`, which can be executed with any JavaScript engine. In this example, we use Node.js:

  ```sh
  node hello.js
  ```

  If everything goes well, you will see `hello world` on your screen.


## Windows support

We plan to provide a Windows installer in the near future.

# Licensing

The [OCaml](./ocaml) directory is the official OCaml compiler (version 4.02.3). Refer to its copyright and license notices for information about its licensing.

This project reused and adapted parts of [js_of_ocaml](https://github.com/ocsigen/js_of_ocaml):
* Some small printing utilities in [pretty printer](./jscomp/js_dump.ml).
* Part of the [Javascript runtime](./jscomp/runtime) support

It adapted two modules [Lam_pass_exits](jscomp/lam_pass_exits.ml) and
[Lam_pass_lets_dce](jscomp/lam_pass_lets_dce.ml) from OCaml's
[Simplif](ocaml/bytecomp/simplif.ml) module, the main
reasons are those optimizations are not optimal for JavaScript
backend.

[Js_main](jscomp/js_main.ml) is adapted from [driver/main](ocaml/driver/main.ml), it is not actually
used, since currently we make this JS backend as a plugin instead, but
it shows that it is easy to assemble a whole compler using OCaml
compiler libraries and based upon that we can add more compilation flags for
JS backend.

[stdlib](jscomp/stdlib) is copied from ocaml's [stdlib](ocaml/stdlib) to have it compiled with
the new JS compiler.

[test](jscomp/test) copied and adapted some modules from ocaml's [testsuite](ocaml/testsuite).


Since our work is derivative work of [js_of_ocaml](http://ocsigen.org/js_of_ocaml/), the license of the BuckleScript components is GPLv2, the same as js_of_ocaml.

## Design goals

1. Readability
 1.   No name mangling.
 2.   Support JavaScript module system.
 3.   Integrate with existing JavaScript ecosystem, for example,
      [npm](https://www.npmjs.com/), [webpack](https://github.com/webpack).
 4.   Straight-forward FFI, generate tds file to target [Typescript](http://www.typescriptlang.org/) for better tooling.

2. Separate and *extremely fast* compilation.

3. Better performance than hand-written Javascript:
   Thanks to the solid type system in OCaml it is possible to optimize the generated JavaScript code.

4. Smaller code than hand written JavaScript, aggressive dead code elimination.

5. Support Node.js, web browsers, and various JavaScript target platforms.

6. Compatible with OCaml semantics modulo C-bindings and Obj, Marshal modules.

## More examples

### A naive benchmark comparing to the Immutable map from Facebook

Below is a *contrived* example to demonstrate our motivation,
it tries to insert 1,000,000 keys into an immutable map, then query it.

```Ocaml
module IntMap = Map.Make(struct
  type t = int
  let compare (x : int) y = compare x y
  end)

let test () =
  let m = ref IntMap.empty in
  let count = 1000000 in
  for i = 0 to count do
    m := IntMap.add i i !m
  done;
  for i = 0 to count  do
    ignore (IntMap.find i !m)
  done

let () = test()

```

The code generated by BuckleScript is a drop-in replacement for the Facebook [immutable](http://facebook.github.io/immutable-js/) library.


``` js
'use strict';
var Immutable = require('immutable');
var Map = Immutable.Map;
var m = new Map();
var test = function() {
    var count = 1000000;
    for(var i = 0; i < count; ++i) {
        m = m.set(i, i);
    }
    for(var j = 0; j < count; ++j) {
        m.get(j);
    }
}

test();
```

Runtime performance:
- BuckleScript Immutable Map: 1186ms
- Facebook Immutable Map: 3415ms

Code Size:
- BuckleScript (Prod mode): 899 Bytes
- Facebook Immutable: 55.3K Bytes

## Status

While most of the OCaml language is covered, because this project is still young there is plenty of work left to be done.

Some known issues are listed as below:

1. Standard libraries distributed with OCaml:

   IO support, we have very limited support for
   `Pervasives.print_endline` and `Pervasives.prerr_endline`, it's
   non-trivial to preserve the same semantics of IO between OCaml and
   Node.js, one solution is to functorize all IO operations. Functors
   are then inlined so there will no be performance cost or code size
   penalty.

   Bigarray, Unix, Num, Str(regex)

   For `Print` to behave correctly, you have to add a newline after
   your output to guarantee it will be flushed, otherwise, it may be buffered.

2. String is immutable, user is expected to compile with the flag `-safe-string` for all modules:

   Note that this flag should be applied to all your modules.

## Question, Comments and Feedback

If you have questions, comments, suggestions for improvement or any other inquiries
regarding this project, feel free to open an issue in the issue tracker.
