extends RenRef
class_name RenToken


const EOL = 'EOL'
const EOF = 'EOF'

const INT       = 'INT'
const FLOAT     = 'FLOAT'
const STR       = 'STR'
const BOOL      = 'BOOL'
const ID        = 'ID'
const DATA_UNIT = [INT, FLOAT, STR, BOOL, ID]

const PLUS     = '+'
const MINUS    = '-'
const MUL      = '*'
const DIV      = '/'
const MOD      = '%'
const FLOORDIV = '//'
const EQUAL    = '='
const POW      = '**'
const ARITHM   = [PLUS, MINUS]
const TERM     = [MUL, DIV, MOD, FLOORDIV, POW]
const OPERATOR = [PLUS, MINUS, MUL, DIV, MOD,
                  FLOORDIV, EQUAL, POW]

const COLON  = ':'
const LPAREN = '('
const RPAREN = ')'
const LBRACK = '['
const RBRACK = ']'
const LCURL  = '{'
const RCURL  = '}'
const DQUOTE = '\"'
const SQUOTE = "\'"
const QUOTE  = [DQUOTE, SQUOTE]
const DELIM  = [
    LPAREN, RPAREN, LBRACK, RBRACK, LCURL,
    RCURL, DQUOTE, SQUOTE, EOL
]

const BLOCK_START = 'START'
const BLOCK_END   = 'END'

const LABEL =  'LABEL'
const MENU  =  'MENU'
const IF =     'IF'
const ELIF =   'ELIF'
const ELSE =   'ELSE'
const AND =    'AND'
const OR =     'OR'
const DEFINE = 'DEFINE'
const DEFAULT = 'DEFAULT'

const KEYWORDS = {
    'True': BOOL,
    'False': BOOL,
    'label': LABEL,
    'menu': MENU,
    'if': IF,
    'elif': ELIF,
    'else': ELSE,
    'and': AND,
    'or': OR,
    'define': DEFINE,
    'default': DEFAULT
}


const DOUBLEOPS = {
    '**': POW,
    '//': FLOORDIV
}


var token_type
var value


func _init(token_type, value=null):
    assert(token_type != null, 'Null token type given')
    self.token_type = token_type
    self.value = value


func _to_string():
    if self.value == null:
        return 'Token(%s)' % [self.token_type]
    elif self.value is String:
        if self.value == self.token_type:
            return 'Token(%s)' % [self.token_type]
        else:
            return 'Token(%s, \"%s\")' % [self.token_type, self.value]
    else:
        return 'Token(%s, %s)' % [self.token_type, self.value]


func is_type(token_type) -> bool:
    """Return true if token matches given token type
    """
    if token_type is String:
        return self.token_type == token_type
    elif token_type is Array:
        return self.token_type in token_type
    else:
        assert(false, 'Tested token must be either string or array.')
        return false


func is_arithm():
    return self.is_type([PLUS, MINUS])


func is_mul():
    return self.is_type([MUL, DIV, FLOORDIV, MOD])
