extends Reference
class_name RenToken


# Enum of all sorts of token types
enum types {
    # TOKEN CATEGORIES
    DATA_TYPE = 1 << 0
    OPERATOR =  1 << 1
    KEYWORD =   1 << 2
    DELIMITER = 1 << 3
    ID =        1 << 4

    # Data types
    INTEGER =     (1 << 0) | (1 << 5)
    FLOAT =       (1 << 0) | (1 << 6)
    BOOL =        (1 << 0) | (1 << 7)
    STRING =      (1 << 0) | (1 << 8)
   
    # Operators   
    PLUS =        (1 << 1) | (1 << 5 )
    MINUS =       (1 << 1) | (1 << 6 )
    MUL =         (1 << 1) | (1 << 7 )
    DIV =         (1 << 1) | (1 << 8 )
    LSHIFT =      (1 << 1) | (1 << 9 )
    RSHIFT =      (1 << 1) | (1 << 10)
    BOR =         (1 << 1) | (1 << 11)
    BAND =        (1 << 1) | (1 << 12)
    XOR =         (1 << 1) | (1 << 13)
    NEGATE =      (1 << 1) | (1 << 14)
    FLOORDIV =    (1 << 1) | (1 << 15)
    POWER =       (1 << 1) | (1 << 16)
    ASSIGN =      (1 << 1) | (1 << 17)
    MOD =         (1 << 1) | (1 << 24)
    AND =         (1 << 1) | (1 << 25)
    OR =          (1 << 1) | (1 << 26)
   
    # Logical ops
    EQUAL =       (1 << 1) | (1 << 18)
    LESS =        (1 << 1) | (1 << 19)
    GREATER =     (1 << 1) | (1 << 20)
    NEQUAL =      (1 << 1) | (1 << 21)
    LEQUAL =      (1 << 1) | (1 << 22)
    GEQUAL =      (1 << 1) | (1 << 23) 
   
    # Keywords   
    LABEL =       (1 << 2) | (1 << 5 )
    MENU =        (1 << 2) | (1 << 6 )
    DEFINE =      (1 << 2) | (1 << 7 )
    DOLLAR =      (1 << 2) | (1 << 8 )
    IF =          (1 << 2) | (1 << 9 )
    ELIF =        (1 << 2) | (1 << 10)
    ELSE =        (1 << 2) | (1 << 11)
   
    # Delimiters
    COLON =       (1 << 3) | (1 << 5 )
    LPAREN =      (1 << 3) | (1 << 6 )
    RPAREN =      (1 << 3) | (1 << 7 )
    LBRACK =      (1 << 3) | (1 << 8 )
    RBRACK =      (1 << 3) | (1 << 9 )
    LCURL =       (1 << 3) | (1 << 10)
    RCURL =       (1 << 3) | (1 << 11)
    COMMA =       (1 << 3) | (1 << 12)
    DOT =         (1 << 3) | (1 << 13)
    EOL =         (1 << 3) | (1 << 14)
    EOF =         (1 << 3) | (1 << 15)
    DQUOTE =      (1 << 3) | (1 << 16)
    SQUOTE =      (1 << 3) | (1 << 17)
    BLOCK_START = (1 << 3) | (1 << 18)
    BLOCK_END =   (1 << 3) | (1 << 19)
}


var token_type
var value


func _init(ttype: int, val=null):
    assert(ttype != null)
    token_type = ttype
    value = val


func _to_string() -> String:
    if value != null:
        if str(value) == '\n':
            return 'Token(%s, value=<newline>)' % [get_type_name()]
        return 'Token(%s, value=\"%s\")' % [get_type_name(), value]
    else:
        return 'Token(%s)' % [get_type_name()] 


func get_type_name() -> String:
    """Get human readable string representation of token_type
    used for debugging.
    """
    var str_repr: String = 'UNKNOWN'
    
    if token_type & types.DATA_TYPE:
        str_repr = 'DATA_TYPE_'
        
        match token_type:
            types.INTEGER:
                str_repr += 'INTEGER'
            types.FLOAT:
                str_repr += 'FLOAT'
            types.STRING:
                str_repr += 'STRING'
            types.BOOL:
                str_repr += 'BOOL'

    elif token_type & types.OPERATOR:
        str_repr = 'OPERATOR_'
        
        match token_type:
            types.PLUS:
                str_repr += 'PLUS'  
            types.MINUS:
                str_repr += 'MINUS' 
            types.MUL:
                str_repr += 'MUL'   
            types.DIV:
                str_repr += 'DIV'   
            types.LSHIFT:
                str_repr += 'LSHIFT'
            types.RSHIFT:
                str_repr += 'RSHIFT'
            types.BOR:
                str_repr += 'BOR'   
            types.BAND:
                str_repr += 'BAND'  
            types.XOR:
                str_repr += 'XOR'   
            types.NEGATE:
                str_repr += 'NEGATE'
            types.FLOORDIV:
                str_repr += 'FLOORDIV'
            types.POWER:
                str_repr += 'POWER' 
            types.ASSIGN:
                str_repr += 'ASSIGN'
            types.MOD:
                str_repr += 'MOD'   
            types.AND:
                str_repr += 'AND'  
            types.OR:
                str_repr += 'OR'   

    elif token_type & types.KEYWORD:
        str_repr = 'KEYWORD_'
        
        match token_type:
            types.LABEL:
                str_repr += 'LABEL'
            types.MENU:
                str_repr += 'MENU'
            types.DEFINE:
                str_repr += 'DEFINE'
            types.DOLLAR:
                str_repr += 'DOLLAR'
            types.IF:
                str_repr += 'IF'
            types.ELIF:
                str_repr += 'ELIF'
            types.ELSE:
                str_repr += 'ELSE'
    
    elif token_type & types.ID:
        str_repr = 'ID'
    
    elif token_type & types.DELIMITER:
        str_repr = 'DELIMITER_'

        match token_type:
            types.COLON:
                str_repr += 'COLON'
            types.LPAREN:
                str_repr += 'LPAREN'
            types.RPAREN:
                str_repr += 'RPAREN'
            types.LBRACK:
                str_repr += 'LBRACK'
            types.RBRACK:
                str_repr += 'RBRACK'
            types.LCURL:
                str_repr += 'LCURL'
            types.RCURL:
                str_repr += 'RCURL'
            types.COMMA:
                str_repr += 'COMMA'
            types.DOT:
                str_repr += 'DOT'
            types.EOL:
                str_repr += 'EOL'
            types.EOF:
                str_repr += 'EOF'
            types.DQUOTE:
                str_repr += 'DQUOTE'
            types.SQUOTE:
                str_repr += 'SQUOTE'
            types.BLOCK_START:
                str_repr += 'BLOCK_START'
            types.BLOCK_END:
                str_repr += 'BLOCK_END'
    
    return str_repr


func is_data_type() -> bool:
    return bool(token_type & types.DATA_TYPE)


func is_operator() -> bool:
    return bool(token_type & types.OPERATOR)


func is_delimiter() -> bool:
    return bool(token_type & types.DELIMITER)


func is_keyword() -> bool:
    return bool(token_type & types.KEYWORD)


func is_identifier() -> bool:
    return bool(token_type & types.ID)


func get_precedence() -> int:
    match token_type:
        types.NEGATE, types.POWER:
            return 1
        types.MUL, types.DIV, types.MOD, types.FLOORDIV:
            return 2
        types.PLUS, types.MINUS:
            return 3
        types.LSHIFT, types.RSHIFT:
            return 4
        types.LESS, types.GREATER, types.LEQUAL, types.GEQUAL:
            return 5
        types.EQUAL, types.NEQUAL:
            return 6
        types.BAND:
            return 7
        types.XOR:
            return 8
        types.BOR:
            return 9
        types.ASSIGN:
            return 10
    return 0
