## Language reference

**Rena** is an interpreted scripting language. When it executes the script, it first compiles it into own bytecode and then its interpreter executes this bytecode.

Blocks of code in Rena are defined by its indentation, one can use either **space or tab to indent blocks**(but don't mix it).

Script consist of a series of **statements** that tell interpreter what to do. The default statement in Rena is so called **Say statement**, it consists of any number of identifiers or strings:

```renpy
"Robert" "Hi, I'm Robert!"  # Robert is who speaks
"Robert entered the room and sat next to you"  # Author speech
```

If a say statement has more than 1 string/id the first one is the speaker by default, if only one speaker is `null` which can be interpreted as author speech.

Other statements include variable definitions, labels, menus, do statements and so on.

### Expressions

Expression is an operation that returns some value. Expressions can consist of some data, like integers, strings, etc., function calls and operators.

#### Operators

| Operator | Name                | Precedence level |
| -------- | ------------------- | ---------------- |
| .        | attribute access    | 0                |
| **       | power               | 1                |
| +        | unary plus          | 2                |
| -        | unary minus         | 2                |
| not      | logical not         | 2                |
| *        | multiply            | 3                |
| /        | divide              | 3                |
| //       | floor divide        | 3                |
| %        | modulo              | 3                |
| +        | plus                | 4                |
| -        | minus               | 4                |
| <<       | bitwise left shift  | 5                |
| >>       | bitwise right shift | 5                |
| <        | less than           | 6                |
| >        | greater than        | 6                |
| <=       | less-equal          | 6                |
| >=       | greater-equal       | 6                |
| ==       | equal               | 7                |
| !=       | not equal           | 7                |
| &        | bitwise and         | 8                |
| ^        | xor                 | 9                |
| \|       | bitwise or          | 10               |
| and      | logical and         | 11               |
| or       | logical or          | 12               |
| in       | in                  | 13               |
| =        | assign              | 14               |



### Keywords

| Keyword | Example usage                     | What it does?                                                |
| ------- | --------------------------------- | ------------------------------------------------------------ |
| label   | `label start:`, `label my_label:` | Creates a label tag which can be jumped to                   |
| jump    | `jump start`, `jump my_label`     | Continues the story from label tag specified after `jump`    |
| call    | `call start`, `call my_label`     | Same as jump, but when it reaches `return` keyword, it returns back to the place from where it jumped and continues the story from there. |
| return  | `return`                          | Ends the script or returns to the `call` point.              |
| do      | `do my_func(args)`                | Runs any function passed as `funcref` to the VM globals inside the script(not needed in expressions) |
| menu    | `menu:`                           | creates a menu block with options and their outcomes.        |

