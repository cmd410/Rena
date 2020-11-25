# RenGo

RenGo is a [RenPy](https://www.renpy.org) inspired plugin for [Godot Engine](https://godotengine.org) that brings renpy-like language for you to help write narrative for your games in a more streamlined fashion. No more convoluted csv tables or json editing, just write story and control flow with menus, conditional statements and emit signals when something significant happens in the story. RenGo is designed to be well integrated into engine to provide maximum flexibility. 

> RenGo is still in early stage of development, API is unstable and is subject to change, **Don't use for production** yet.

## Current progress

- [ ] Lexer(WIP)
  - [x] parsing ints, floats
  - [x] parsing booleans
  - [x] parsing identifiers and keywords
  - [x] parsing strings
    - [ ] parse also \xXX and \uXXXX
- [ ] Parser(WIP)
- [ ] Interpreter(ToDo)