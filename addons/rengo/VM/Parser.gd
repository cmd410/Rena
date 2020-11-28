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


func skip_lines():
    while self.current_token.token_type == RenToken.EOL:
        eat(RenToken.EOL)


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


func variable() -> RenResult:
    var token = self.current_token
    var res = eat(RenToken.ID)
    if res is RenERR:
        return res
    return RenOK.new(RenVar.new(token))


func assignment() -> RenResult:
    var res = variable()
    if res is RenERR:
        return res
    
    var id = res.value
    
    var op = self.current_token
    res = eat(RenToken.EQUAL)
    if res is RenERR:
        return res

    res = arithm()
    if res is RenERR:
        return res
    else:
        return RenOK.new(RenBinOp.new(id, op, res.value))


func label() -> RenResult:
    
    var res = eat(RenToken.LABEL)
    if res is RenERR:
        return res
    
    var token = self.current_token
    
    res = eat(RenToken.ID)
    if res is RenERR:
        return res
    
    res = eat(RenToken.COLON)
    if res is RenERR:
        return res
    
    res = eat(RenToken.EOL) 
    if res is RenERR:
        return res
    
    res = compound()
    if res is RenERR:
        return res
    
    var node = RenLabel.new(token)
    node.add_child(res.value)
    return RenOK.new(node)


func say() -> RenResult:
    var tokens: Array = []
    while not self.current_token.token_type in [RenToken.EOL, RenToken.BLOCK_END]:
        match self.current_token.token_type:
            RenToken.ID, RenToken.STR:
                tokens.append(self.current_token)
                eat([RenToken.ID, RenToken.STR])
            _:
                return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected token in say statement: %s' % [self.current_token])
    if tokens.empty():
        return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected end of say statement')
    
    var node = RenSay.new()
    for token in tokens:
        match token.token_type:
            RenToken.ID:
                node.add_child(RenVar.new(token))
            RenToken.STR:
                node.add_child(RenString.new(token))
    return RenOK.new(node)


func menu() -> RenResult:
    var res = eat(RenToken.MENU)
    if res is RenERR:
        return res
    res = eat(RenToken.COLON)
    if res is RenERR:
        return res
    res = eat(RenToken.EOL)
    if res is RenERR:
        return res
    
    skip_lines()
    res = eat(RenToken.BLOCK_START)
    if res is RenERR:
        return res

    var token = self.current_token
    res = eat(RenToken.STR)
    if res is RenERR:
        return res
    
    var menu = null
    # Parsing first menu option or line
    match current_token.token_type:
        RenToken.EOL:
            menu = RenMenu.new(token.value)
            res = eat(RenToken.EOL)
            if res is RenERR:
                return res
        RenToken.COLON:
            var option = RenOption.new(token)
            menu = RenMenu.new()
            menu.add_child(option)
            res = eat(RenToken.COLON)
            if res is RenERR:
                return res
            res = eat(RenToken.EOL)
            if res is RenERR:
                return res
            skip_lines()
            res = compound()
            if res is RenERR:
                return res
            option.add_child(res.value)
        _:
            return error(RenERR.TOKEN_UNKNOWN, 'Unexpected token while p: %s')
    
    skip_lines()
    
    while self.current_token.token_type == RenToken.STR:
        token = self.current_token
        res = eat(RenToken.STR)
        if res is RenERR:
            return res
        res = eat(RenToken.COLON)
        if res is RenERR:
            return res
        res = eat(RenToken.EOL)
        if res is RenERR:
            return res
        skip_lines()
        res = compound()
        if res is RenERR:
            return res
        var option = RenOption.new(token)
        option.add_child(res.value)
        menu.add_child(option)
        skip_lines()
    res = eat(RenToken.BLOCK_END)
    if res is RenERR:
        return res
    return RenOK.new(menu)

func statement() -> RenResult:
    skip_lines()
    var node = null
    match self.current_token.token_type:
        RenToken.DEFINE, RenToken.DEFAULT:
            var token = self.current_token
            var res = eat([RenToken.DEFINE, RenToken.DEFAULT])
            if res is RenERR:
                return res
            
            node = RenDef.new(token)
            res = assignment()
            if res is RenERR:
                return res
            node.add_child(res.value)
        RenToken.LABEL:
            var res = label()
            if res is RenERR:
                return res
            node = res.value
        RenToken.ID, RenToken.STR:
            var res = say()
            if res is RenERR:
                return res
            node = res.value
        RenToken.MENU:
            var res = menu()
            if res is RenERR:
                return res
            node = res.value
        _:
            return error(RenERR.TOKEN_UNEXPECTED, 'Got unexpected token: %s' % [self.current_token])
    
    match self.current_token.token_type:
        RenToken.EOL:
            var res = eat(RenToken.EOL)
            if res is RenERR:
                return res
        RenToken.BLOCK_END:
            pass
        _:
           return error(RenERR.TOKEN_UNEXPECTED, 'Unexpeced end of line.')
    return RenOK.new(node)


func compound() -> RenResult:
    skip_lines()
    var result = eat(RenToken.BLOCK_START)
    if result is RenERR:
        return result

    var node = RenAST.new()
    while self.current_token.token_type != RenToken.BLOCK_END:
        result = statement()
        skip_lines()
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
