# RenGo bytecode spec

## Conventions

Enums:

```c
enum BCode {
    LOAD_NAME
    LOAD_CONST
    
    ASSIGN_NAME
    ASSIGN_IF_NONE
    ASSIGN_IF_EXISTS
    
    JUMP
    JUMP_IF_FALSE
    
    POP_TOP

    # BinOps
    ADD, SUB, MUL, DIV, FLOORDIV, POW
    MOD, POW, LSHIFT, RSHIFT, XOR, BOR, BAND,
    EXEQ, NOEQ, LESS, GREATER, LEQ, GEQ, AND, OR

    # UnaryOps
    POSITIVE, NEGATIVE, NOT

    # Complex types
    BUILD_LIST

    # Statements
    SAY
}


enum DataTypes {
    BOOL
    UINT8
    UINT16
    UINT32
    
    INT64
    
    FLOAT

    STRING
}
```

## Basic Operations

### Load constant

>  Push a constant value to the stack.

Scheme:

| Field name     | length                   | type                                              | Possible values                                              |
| -------------- | ------------------------ | ------------------------------------------------- | ------------------------------------------------------------ |
| Operation code | 1                        | Byte                                              | BCode.__LOAD_CONST__                                         |
| Data type      | 1                        | Byte                                              | Variant of DataType                                          |
| Value          | depends on __Data type__ | UINT8, UINT16, UINT32, INT64, FLOAT, STRING, BOOL | Integers in range `[-2^63, 2^63 - 1]` or Float32 or utf-8 string or Boolean |

Size of value depends on `DataTypes` variant.

If Data type is DataType.__STRING__ first 4 bytes of value is string length in bytes. Strings are encoded in utf-8.

### Load variable

> Lookup variable by its name and push its value to the stack

| Field name     | length               | type   | Possible values      |
| -------------- | -------------------- | ------ | -------------------- |
| Operation code | 1                    | Byte   | BCode.__LOAD_NAME__  |
| Length         | 4                    | UINT32 | UINT32               |
| Name           | see __Length__ field | STRING | utf-8 encoded string |

### Assignments

> Pop value from stack, assign it to name

Scheme:

| Field name     | length              | type   | Possible values                                              |
| -------------- | ------------------- | ------ | ------------------------------------------------------------ |
| Operation code | 1                   | Byte   | BCode.__ASSIGN_NAME__, __ASSIGN_IF_NONE__, __ASSIGN_IF_EXISTS__ |
| Name length    | 4                   | UINT32 | Integers in range `[0, 2^32 - 1]`                            |
| Name           | see __Name length__ | STRING | ASCII string                                                 |

Operation code changes interpretation:

- __ASSIGN_NAME__ - assign name unconditionally, result of `define` keyword
- __ASSIGN_IF_NONE__ - assign name only if it holds no value, result of `default` keyword
- __ASSIGN_IF_EXISTS__ - assign name if this name exists, otherwise raise error, result of `$` operator

## Compound types

### Lists(Arrays)

> Can contain data of different types.

`BCode.BUILD_LIST` - Creates new list from current stack.

Example bytecode:

```
LOAD_CONST 1
LOAD_CONST 2.2
LOAD_CONST "string"
BUILD_LIST
LOAD_CONST 42
BUILD_LIST
```

Will result in list `[[1, 2.2, "string"], 42]`

## Statements

### Say

> Turns current stack into say statement.

`BCode.SAY`

Example bytecode:

```
LOAD_CONST "Mario"
LOAD_CONST "It's me, Mario!"
SAY
```

Will result in say statement: `Mario: It's me, Mario!`