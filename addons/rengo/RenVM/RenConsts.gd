extends Node

# Some helper constants

# Maps TokenType int to human readable name
var types_to_display_name = {}

const valid_id_chars = (
    '_' +
    '1234567890' +
    'qwertyuiopasdfghjklzxcvbnm' + 
    'QWERTYUIOPASDFGHJKLZXCVBNM'
    )


const KEYWORDS = {
    '$': RenToken.types.K_DOLLAR,
    'as': RenToken.types.K_AS,
    'at': RenToken.types.K_AT,
    'behind': RenToken.types.K_BEHIND,
    'call': RenToken.types.K_CALL,
    'expression': RenToken.types.K_EXPRESSION,
    'hide': RenToken.types.K_HIDE,
    'if': RenToken.types.K_IF,
    'in': RenToken.types.K_IN,
    'image': RenToken.types.K_IN,
    'init': RenToken.types.K_INIT,
    'jump': RenToken.types.K_JUMP,
    'menu': RenToken.types.K_MENU,
    'scene': RenToken.types.K_SCENE,
    'show': RenToken.types.K_SHOW,
    'with': RenToken.types.K_WITH,
    'while': RenToken.types.K_WHILE,
    'label': RenToken.types.K_LABEL,
    'or': RenToken.types.K_OR,
    'and': RenToken.types.K_AND,
    'not': RenToken.types.K_NOT,
    'is': RenToken.types.K_IS
}


const TOKEN_LOOKUP = {
    '+': RenToken.types.M_PLUS,
    '-': RenToken.types.M_MINUS,
    '*': RenToken.types.M_MUL,
    '/': RenToken.types.M_DIV,
    '+=': RenToken.types.M_IPLUS,
    '-=': RenToken.types.M_IMINUS,
    '*=': RenToken.types.M_IMUL,
    '/=': RenToken.types.M_IDIV,
    '//': RenToken.types.M_FLOORDIV,
    '**': RenToken.types.M_POWER,
    '<<': RenToken.types.B_LSHIFT,
    '>>': RenToken.types.B_RSHIFT,
    '~': RenToken.types.B_NEGATE,
    '|': RenToken.types.B_OR,
    '^': RenToken.types.B_XOR,
    '&': RenToken.types.B_AND,
    ':': RenToken.types.COLON,
    '(': RenToken.types.LPAREN,
    ')': RenToken.types.RPAREN,
    '[': RenToken.types.LBRACK,
    ']': RenToken.types.RBRACK
}


func _ready():
    for value in RenToken.types:
        var key = RenToken.types[value]
        types_to_display_name[key] = value
