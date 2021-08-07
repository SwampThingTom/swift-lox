// Taken from Robert Nystrom's Crafting Interpreters.
// https://github.com/munificent/craftinginterpreters/blob/master/tool/lib/src/term.dart
//
// Used under MIT license.
// https://github.com/munificent/craftinginterpreters/blob/master/LICENSE
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

/// Utilities for printing to the terminal.
import 'dart:io';

final _cyan = _ansi('\u001b[36m');
final _gray = _ansi('\u001b[1;30m');
final _green = _ansi('\u001b[32m');
final _magenta = _ansi('\u001b[35m');
final _pink = _ansi('\u001b[91m');
final _red = _ansi('\u001b[31m');
final _yellow = _ansi('\u001b[33m');
final _none = _ansi('\u001b[0m');
final _resetColor = _ansi('\u001b[39m');

String cyan(Object message) => "$_cyan$message$_none";
String gray(Object message) => "$_gray$message$_none";
String green(Object message) => "$_green$message$_resetColor";
String magenta(Object message) => "$_magenta$message$_resetColor";
String pink(Object message) => "$_pink$message$_resetColor";
String red(Object message) => "$_red$message$_resetColor";
String yellow(Object message) => "$_yellow$message$_resetColor";

void clearLine() {
  if (_allowAnsi) {
    stdout.write("\u001b[2K\r");
  } else {
    print("");
  }
}

void writeLine([String line]) {
  clearLine();
  if (line != null) stdout.write(line);
}

bool get _allowAnsi =>
    !Platform.isWindows && stdioType(stdout) == StdioType.terminal;

String _ansi(String special, [String fallback = '']) =>
    _allowAnsi ? special : fallback;
