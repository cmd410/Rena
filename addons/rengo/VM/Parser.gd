extends RenRef
class_name RenParser


signal exception(err)


var lexer: RenLexer = null
var current_token: RenToken = null


func _init(lexer: RenLexer):
    self.lexer = lexer as RenLexer
    var result = lexer.get_next_token()
    if result is RenERR:
        return
    self.current_token = result.value
    assert(self.lexer != null, 'Parser needs a valid lexer!')


func error(err_type: String, message: String) -> RenERR:
    var err = self.lexer.error(err_type, message)
    emit_signal('exception', err)
    return err


func eat(token_type) -> RenResult:
    if self.current_token.is_type(token_type):
        var result = self.lexer.get_next_token()
        if result is RenERR:
            return result
        self.current_token = result.value
        return RenOK.new(0)
    else:
        return error(
            RenERR.TOKEN_UNEXPECTED,
            'Got unexpected token: %s, but must be %s' % [self.current_token, token_type]
        )


func factor() -> RenResult:
    if self.current_token.is_type(RenToken.DATA_UNIT):
        var token = current_token
        
        var result = eat(RenToken.DATA_UNIT)
        if result is RenERR:
            return result
        
        match token.token_type:
            RenToken.INT, RenToken.FLOAT:
                return RenOK.new(RenNum.new(token))
            RenToken.BOOL:
                return RenOK.new(RenBool.new(token))
            RenToken.STR:
                return RenOK.new(RenString.new(token))
            RenToken.ID:
                return RenOK.new(RenVar.new(token))
            _:
                return error(
                    RenERR.CODING_ERROR,
                    'Unmathced data unit type %s in factor function.' % [token]
                )
    elif self.current_token.token_type == RenToken.LPAREN:
        eat(RenToken.LPAREN)
        var result = arithm()
        if result is RenERR:
            return result
        var node = result.value
        result = eat(RenToken.RPAREN)
        if result is RenERR:
            return result
        return RenOK.new(node)
    else:
        return error(
            RenERR.TOKEN_UNEXPECTED,
            'Expected number, string, boolean or identifier, got %s.' % [self.current_token]
        )


func term() -> RenResult:
    var result = factor()
    if result is RenERR:
        return result

    var node = result.value
    while self.current_token.is_type(RenToken.TERM):
        var token = self.current_token
        result = eat(RenToken.TERM)
        if result is RenERR:
            return result
        result = factor()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)

    return RenOK.new(node)


func arithm() -> RenResult:
    var result = term()
    if result is RenERR:
        return result

    var node = result.value
    while self.current_token.is_type(RenToken.ARITHM):
        var token = self.current_token
        result = eat(RenToken.ARITHM)
        if result is RenERR:
            return result
        result = term()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)

    return RenOK.new(node)


func compound() -> RenResult:
    var result = eat(RenToken.BLOCK_START)
    if result is RenERR:
        return result

    var node = RenAST.new()
    while self.current_token.token_type != RenToken.BLOCK_END:
        while self.current_token.token_type == RenToken.EOL:
            eat(RenToken.EOL)

        result = arithm()   # WIP temporary testing functions
        
        if result is RenERR:
            return result
        
        node.add_child(result.value)
    
    eat(RenToken.BLOCK_END)

    return RenOK.new(node)


func script():
    if self.current_token == null:
        return error('ParserInitError', 'Parser got no tokens to process.')
    var result = compound()
    if result is RenERR:
        return result
    
    var node = result.value

    result = eat(RenToken.EOF)

    if result is RenERR:
        return result

    return RenOK.new(node)
