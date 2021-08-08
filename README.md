This is a Swift port of the Lox interpreter from Robert Nystrom's book "[Crafting Interpreters][]".
The original Java source can be found at https://github.com/munificent/craftinginterpreters.

[crafting interpreters]: http://craftinginterpreters.com

## Building

To build, run:

```
swift build
```

This builds three targets.

* `Lox` is a library containing the parser and interpreter.
* `generate_ast` is an executable that generates the AST classes.
* `lox-macos` is a MacOS command line executable that wraps the Lox library.

### Modifying the AST

The `generate_ast` tool is only needed if you change the AST definitions for Lox.
The generated classes are already checked into this repository.

If you do need to run it, you can use the following script.
It builds the `generate_ast` executable and runs it.

```
bin/generate-ast
```

After running `generate-ast`, you'll need to rebuild the `Lox` library target
and the `lox-macos` executable.

```
swift build --product lox-macos
```

## Running

Once lox has been built, you can run it from the command line at the repo's root directory.

To run a specific script, pass the full path of the Lox script to `bin/slox`:

```
bin/slox [script]
```

To run in interactive mode, simply run it with no parameters:

```
bin/slox
```

## Testing

I have included the original test runner and 
full test suite from the Crafting Interpreters repository.
Using the original test runner provides confidence that the Swift implementation
fully matches the language specification.

Since the test runner is written in [Dart][], you will need to have that installed.
If you don't already, you can follow these [instructions][install-dart].

[dart]: https://dart.dev/
[install-dart]: https://dart.dev/get-dart

Next, you'll need to fetch the test runner's dependencies.
I have provided a `setup` script to make this easier.
It only needs to be run once.

```
bin/setup
```

Once the Swift lox executable has been built and the Dart dependencies have been installed,
you can run the tests using another script.

```
bin/run-tests
```

## Running on Raspberry Pi

I thought it would be fun to add Lox to the list of languages I
can use on my Raspberry Pi.
If you want to do the same, all you need to do is install the Swift SDK on your Raspberry Pi following these instructions:

```
curl -s https://packagecloud.io/install/repositories/swift-arm/release/script.deb.sh | sudo bash
sudo apt install swiftlang
```

After that, run `swift build` as usual.

Unfortunately, I didn't have as much luck installing the Dart SDK as they currently don't make 
their ARM64 build available as a Debian package (https://github.com/dart-lang/sdk/issues/26953).
So I was unable to get the tests to run on the Raspberry Pi.

## Notes

My original plan when I picked up "Crafting Interpreters" was to make minor changes to the
language as I went.
However the further I got the more I realized it would be better to implement a straight port
of the language first and then start from scratch when I am ready to create my own scripting
language.
This is why I didn't start with the Lox tests from the beginning.
In hindsight, I wish I had followed a TDD approach using those tests.
Some bugs from each chapter weren't found and fixed until later, and a few not until I had the
full test suite running after completing all of the chapters.

Although I used some Swift niceties in this implementation (like guard statements and enums),
for the most part I tried to make it match the Java implementation.
The one area where that turned out to be a huge pain was using `Any?` to store Lox values
in the same way that the Java implementation uses `Object`.
This let me match the intent of the Java implementation which relies on the underlying Java
types to represent Lox types, including the use of Java `null` for Lox `nil`.
However, Swift's stronger typing rules made this difficult and was responsible for all of the
harder to track down implementation bugs.
I will likely change this to use a `LoxValue` type to encapsulate Lox types, including an
explicit `LoxNil` type.

One change I did keep was implementing individual runtime errors rather
than relying on Lox's single RuntimeError exception.
This would be useful if errors were handled differently, or if the error
message wasn't created by the `Interpreter`.
As it is, however, this was more work for zero value.
