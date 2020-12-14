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

    OP
}


enum OPs {
    ADD, SUB
    MUL, DIV, FLOORDIV
    POSITIVE, NEGATIVE
    POW
}

enum DataTypes {
    UINT8
    UINT16
    UINT32
    
    INT64
    
    FLOAT
}

```

## Basic Operations

### Load constant

>  Push a constant numeric value to the stack.

Scheme:

| Field name     | length                   | type                                | Possible values                                  |
| -------------- | ------------------------ | ----------------------------------- | ------------------------------------------------ |
| Operation code | 1                        | Byte                                | BCode.__LOAD_CONST__                             |
| Data type      | 1                        | Byte                                | Variant of DataType                              |
| Value          | depends on __Data type__ | UINT8, UINT16, UINT32, INT64, FLOAT | Integers in range `[-2^63, 2^63 - 1]` or Float32 |

Size of value depends on `DataTypes` variant.

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

