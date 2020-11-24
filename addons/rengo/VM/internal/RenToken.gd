extends RenRef
class_name RenToken


const EOL = 'EOL'
const EOF = 'EOF'

const PLUS = '+'
const MINUS = '-'
const MUL = '*'
const DIV = '/'
const FLOORDIV = '//'
const MOD = '%'

const LPAREN = '('
const RPAREN = ')'

const BLOCK_START = 'START'
const BLOCK_END = 'END'


var token_type
var value


func _init(token_type, value=null):
    assert(token_type != null, 'Null token type given')
    self.token_type = token_type
    self.value = value


func test_type(token_type) -> bool:
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
    return self.test_type([PLUS, MINUS])


func is_mul():
    return self.test_type([MUL, DIV, FLOORDIV, MOD])
