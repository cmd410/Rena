extends Node



var TType_to_display_name = {}

const valid_id_chars = (
    '_' +
    '1234567890' +
    'qwertyuiopasdfghjklzxcvbnm' + 
    'QWERTYUIOPASDFGHJKLZXCVBNM'
    )


# Enum of all sorts of token types
enum TType {
    EOF = 0
    EOL = 1 << 13
    # Primitive data types
    # that can be parsed at Lexer level
    DT_INTEGER = 1 << 1
    DT_FLOAT = 1 << 2
    DT_BOOL = 1 << 3
    DT_STRING = 1 << 4

    # Float or Int or Bool
    DT_NUMBER = 1 | 2 | 4

    # Math Ops
    M_PLUS = 1 << 5
    M_MINUS = 1 << 6
    M_MUL = 1 << 7
    M_DIV = 1 << 8
    M_MOD = 1 << 9
    M_FLOORDIV = 1 << 10
    M_POWER = 1 << 11

    # In-place math ops
    INPLACE = 1 << 12
    M_IPLUS = (1 << 5) | (1 << 12)
    M_IMINUS = (1 << 6) | (1 << 12)
    M_IMUL = (1 << 7) | (1 << 12)
    M_IDIV = (1 << 8) | (1 << 12)

    # Compounds for fast precedence checks
    M_ADDITIVE = (1 << 5) | (1 << 6)
    M_MULTIPLICATIVE = (1 << 7) | (1 << 8) | (1 << 9) | (1 << 10)

    # Bitwise Ops
    B_NEGATE = 1 << 16
    B_OR = 1 << 17
    B_AND = 1 << 18
    B_XOR = 1 << 19
    B_LSHIFT = 1 << 20
    B_RSHIFT = 1 << 21

    # Keywords
    K_DOLLAR = 1 << 22
    K_AS = 1 << 23
    K_AT = 1 << 24
    K_BEHIND = 1 << 25
    K_CALL = 1 << 26
    K_EXPRESSION = 1 << 27
    K_HIDE = 1 << 28
    K_IF = 1 << 29
    K_IN = 1 << 30
    K_IMAGE = 1 << 31
    K_INIT = 1 << 32
    K_JUMP = 1 << 33
    K_MENU = 1 << 34
    K_ONLAYER = 1 << 35
    K_RETURN = 1 << 36
    K_SCENE = 1 << 37
    K_SHOW = 1 << 38
    K_WITH = 1 << 39
    K_WHILE = 1 << 40
    K_LABEL = 1 << 41
    K_TRANSFORM = 1 << 42
    K_OR = 1 << 43
    K_AND = 1 << 44
    K_NOT = 1 << 45
    K_IS = 1 << 47

    KEYWORD = ((1 << 22) | (1 << 23) |
               (1 << 24) | (1 << 25) |
               (1 << 26) | (1 << 27) |
               (1 << 28) | (1 << 29) |
               (1 << 30) | (1 << 31) |
               (1 << 32) | (1 << 33) |
               (1 << 34) | (1 << 35) |
               (1 << 36) | (1 << 37) |
               (1 << 38) | (1 << 39) |
               (1 << 40) | (1 << 41) |
               (1 << 42) | (1 << 43) |
               (1 << 44) | (1 << 45) |
               (1 << 46) | (1 << 47) )

    # Delimiters
    LPAREN = 1 << 48
    RPAREN = 1 << 49

    LBRACK = 1 << 50
    RBRACK = 1 << 51
    
    S_QUOTE = 1 << 52
    D_QUOTE = 1 << 53
    QUOTE = (1 << 52) | (1 << 53)

    PERIOD = 1 << 54
    DOT = 1 << 58

    # Other
    IDENTIFIER = 1 << 59
    EQUAL = 1 << 60  # =
    COMP = 1 << 61  # ==
    LESS = 1 << 62  # <
    GREATER = 1 << 63  # >
    LEQ = (1 << 61) | (1 << 62)  # <=
    GEQ = (1 << 61) | (1 << 63)  # >=
    COMPARISON = (1 << 61) | (1 << 62) | (1 << 63) 

    BLOCK_END = 1 << 13
    BLOCK_START = 1 << 14

    BLOCK_BOUNDARY = (1 << 13) | (1 << 14)

    COLON = 1 << 15
}


const KEYWORDS = {
    '$': TType.K_DOLLAR,
    'as': TType.K_AS,
    'at': TType.K_AT,
    'behind': TType.K_BEHIND,
    'call': TType.K_CALL,
    'expression': TType.K_EXPRESSION,
    'hide': TType.K_HIDE,
    'if': TType.K_IF,
    'in': TType.K_IN,
    'image': TType.K_IN,
    'init': TType.K_INIT,
    'jump': TType.K_JUMP,
    'menu': TType.K_MENU,
    'onlayer': TType.K_ONLAYER,
    'scene': TType.K_SCENE,
    'show': TType.K_SHOW,
    'with': TType.K_WITH,
    'while': TType.K_WHILE,
    'label': TType.K_LABEL,
    'or': TType.K_OR,
    'and': TType.K_AND,
    'not': TType.K_NOT,
    'is': TType.K_IS
}


const OPERATORS = {
    '+': TType.M_PLUS,
    '-': TType.M_MINUS,
    '*': TType.M_MUL,
    '/': TType.M_DIV,
    '+=': TType.M_IPLUS,
    '-=': TType.M_IMINUS,
    '*=': TType.M_IMUL,
    '/=': TType.M_IDIV,
    '//': TType.M_FLOORDIV,
    '**': TType.M_POWER,
    '<<': TType.B_LSHIFT,
    '>>': TType.B_RSHIFT,
    '~': TType.B_NEGATE,
    '|': TType.B_OR,
    '^': TType.B_XOR,
    '&': TType.B_AND,
    ':': TType.COLON,
}


func _ready():
    for value in TType:
        var key = TType[value]
        TType_to_display_name[key] = value
