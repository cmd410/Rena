# Rena

Rena is a scripting language for [Godot Engine](https://godotengine.org), designed with a goal of turning writing interactive dialogues for games a very enjoyable and intuitive process. Rena is heavily inspired by [RenPy](https://www.renpy.org), an awesome engine for visual novels, although Rena tries to be more general purpose. 

Its not a framework. It does not enforce certain project structure or anything like that. Its just a small virtual machine that interprets code, how you integrate it in your project is completely up to you. 

> Rena is still in active development, some features might be missing or buggy, **Not recommended for production** yet. If you are experiencing problems, report them in the issues tab, I'll try to fix everything as fast as I can. You can also request features, of course.

## Features

- **say statements** representing characters' speech
- **variables** which can be defined and change them at runtime or from gdscript
- **if statements** to control the flow with conditions
- **menus** to get user input in the dialogue
- **gdscript functions** of your choice can be called directly from Rena whenever you need it with arbitrary number of arguments
- **wide range of operators** for all kinds of  expressions you might need.
- **Arrays** and **Dictionaries** fully supported