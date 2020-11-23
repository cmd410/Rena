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
    'label':  RenToken.types.LABEL, 
    'menu':   RenToken.types.MENU,
    'define': RenToken.types.DEFINE,
    'if':     RenToken.types.IF,
    'elif':   RenToken.types.ELIF,
    'else':   RenToken.types.ELSE
}


const TOKEN_LOOKUP = {
    '+':   RenToken.types.PLUS,
    '-':   RenToken.types.MINUS,
    '*':   RenToken.types.MUL,
    '/':   RenToken.types.DIV,
    '//':  RenToken.types.FLOORDIV,
    '**':  RenToken.types.POWER,
    '<<':  RenToken.types.LSHIFT,
    '>>':  RenToken.types.RSHIFT,
    '~':   RenToken.types.NEGATE,
    '|':   RenToken.types.BOR,
    '^':   RenToken.types.XOR,
    '&':   RenToken.types.BAND,
    ':':   RenToken.types.COLON,
    '(':   RenToken.types.LPAREN,
    ')':   RenToken.types.RPAREN,
    '[':   RenToken.types.LBRACK,
    ']':   RenToken.types.RBRACK,
    '\"':  RenToken.types.DQUOTE,
    "\'":  RenToken.types.SQUOTE,
    '.':   RenToken.types.DOT,
    ',':   RenToken.types.COMMA,
    '\n':  RenToken.types.EOL,
    '$':   RenToken.types.DOLLAR,
    '==':  RenToken.types.EQUAL,
    '<':   RenToken.types.LESS,
    '>':   RenToken.types.GREATER,
    '!=':  RenToken.types.NEQUAL,
    '<=':  RenToken.types.LEQUAL,
    '>=':  RenToken.types.GEQUAL,
    '%':   RenToken.types.MOD
}


func _ready():
    for value in RenToken.types:
        var key = RenToken.types[value]
        types_to_display_name[key] = value
