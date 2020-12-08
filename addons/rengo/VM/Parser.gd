extends RenRef
class_name RenParser


signal exception(err)
signal ast_built(ast)


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
    # Consumes Token of given token_type and gets new token
    # Returns RenOK on success and RenERR if token_type does not match
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


func eat_chain(chain: Array) -> RenResult:
    # Same as eat but eats token chains
    for t in chain:
        var res = eat(t)
        if res is RenERR:
            return res
    return RenOK.new(0)


func skip_lines():
    while self.current_token.token_type == RenToken.EOL:
        eat(RenToken.EOL)


func list() -> RenResult:
    var node = RenList.new(self.current_token)
    var res = eat(RenToken.LBRACK)
    if res is RenERR:
        return res

    skip_lines()
    
    while self.current_token.token_type != RenToken.RBRACK:
        
        res = expr()
        if res is RenERR:
            return res
        
        var value = res.value
        node.add_child(value)
        
        skip_lines()
        
        if self.current_token.is_type(RenToken.COMMA):
            res = eat(RenToken.COMMA)
            if res is RenERR:
                return res
            skip_lines()
        
        elif self.current_token.is_type(RenToken.RBRACK):
            break
        
        else:
            return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected token while parsing list: %s' % [self.current_token.token_type])
    
    res = eat(RenToken.RBRACK)
    if res is RenERR:
        return res
    
    return RenOK.new(node)


func dict() -> RenResult:
    # Create new dict AST item
    var node = RenDict.new(self.current_token)
    
    var res = eat(RenToken.LCURL)
    if res is RenERR:
        return res
    
    skip_lines()
    while self.current_token.token_type != RenToken.RCURL:
        
        # Parse dict key
        res = expr()
        if res is RenERR:
            return res
        var key = res.value
        
        # key: value separator
        res = eat(RenToken.COLON)
        if res is RenERR:
            return res
        
        # Parse dict value
        res = expr()
        if res is RenERR:
            return res
        var value = res.value
        
        # Add DictItem
        node.add_child(RenDictItem.new(key, value))
        
        skip_lines()

        # After each item we expect either a comma or closing curly bracket
        if self.current_token.is_type(RenToken.COMMA):
            res = eat(RenToken.COMMA)
            if res is RenERR:
                return res
            skip_lines()
        elif self.current_token.is_type(RenToken.RCURL):
            break
        else:
            return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected token while parsing dictionary: %s' % [self.current_token.token_type])
    
    # Eat closing curly bracket
    res = eat(RenToken.RCURL)
    if res is RenERR:
        return res
    
    return RenOK.new(node)


func comma_separated_exprs(stop_token) -> RenResult:
    # Returns expression separated by commas as an Array
    # Until stop_token is met, does not eat stop_token tho
    # example:
    # 1, "string", 1+2, varibale 
    
    var values = []
    
    while not self.current_token.is_type(stop_token):
        var res = expr()
        if res is RenERR:
            return res
        values.append(res.value)
        if self.current_token.is_type(stop_token):
            break
        else:
            res = eat(RenToken.COMMA)
            if res is RenERR:
                return res
    
    return RenOK.new(values)


# Following functions used for parsing expressions
# They are different operations in order of precedence
func factor() -> RenResult:
    # This is pretty much responsible for parsing various data units
    # like numbers, varibales, lists, dicts, calls to functions
    # also instantly parses power operator as it should be applied first
    
    # Parse data units
    if self.current_token.is_type(RenToken.DATA_UNIT):
        var token = current_token
        var result = null
        var node = null
        
        match token.token_type:
            
            RenToken.INT, RenToken.FLOAT:
                node = RenNum.new(token)
                result = eat(RenToken.DATA_UNIT)
                if result is RenERR:
                    return result
            
            RenToken.BOOL:
                node = RenBool.new(token)
                result = eat(RenToken.DATA_UNIT)
                if result is RenERR:
                    return result
            
            RenToken.STR:
                node = RenString.new(token)
                result = eat(RenToken.DATA_UNIT)
                if result is RenERR:
                    return result
            
            RenToken.ID:
                result = variable()
                if result is RenERR:
                    return result
                node = result.value
            _:
                return error(
                    RenERR.CODING_ERROR,
                    'Unmathced data unit type %s in factor function.' % [token]
                )
        
        # Power operation should be first to apply
        if self.current_token.token_type == RenToken.POW:
            token = self.current_token
            result = eat(RenToken.POW)
            if result is RenERR:
                return result
            result = factor()
            if result is RenERR:
                return result
            return RenOK.new(RenBinOp.new(node, token, result.value))
        
        # Parse nested namespaces
        elif self.current_token.token_type == RenToken.PERIOD:
            while self.current_token.token_type == RenToken.PERIOD:
                result = eat(RenToken.PERIOD)
                if result is RenERR:
                    return result
                result = variable()
                if result is RenERR:
                    return result
                var new_node = result.value
                if new_node is RenVar:
                    new_node.add_child(node)
                elif new_node is RenInvoke or new_node is RenKeyAccess:
                    new_node.get_child(0).add_child(node)
                node = new_node

        return RenOK.new(node)
    
    # Parse Unary Operators
    elif self.current_token.is_type(RenToken.ARITHM):
        var token = self.current_token
        eat(RenToken.ARITHM)
        var res = factor()
        if res is RenERR:
            return res
        return RenOK.new(RenUnOp.new(token, res.value))
    
    # Parse expressions in parenthesis
    elif self.current_token.token_type == RenToken.LPAREN:
        eat(RenToken.LPAREN)
        
        var result = expr()
        if result is RenERR:
            return result
        var node = result.value
        
        result = eat(RenToken.RPAREN)
        if result is RenERR:
            return result
        
        return RenOK.new(node)
    
    elif self.current_token.token_type == RenToken.LBRACK:
        return list()
    
    elif self.current_token.token_type == RenToken.LCURL:
        return dict()
    
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


func shifts() -> RenResult:
    var result = arithm()
    if result is RenERR:
        return result
    
    var node = result.value
    while self.current_token.is_type(RenToken.SHIFTS):
        var token = self.current_token
        result = eat(RenToken.SHIFTS)
        if result is RenERR:
            return result
        result = arithm()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)
    
    return RenOK.new(node)


func cmp() -> RenResult:
    var result = shifts()
    if result is RenERR:
        return result
    
    var node = result.value
    while self.current_token.is_type(RenToken.CMP):
        var token = self.current_token
        result = eat(RenToken.CMP)
        if result is RenERR:
            return result
        result = shifts()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)
    
    return RenOK.new(node)


func exact() -> RenResult:
    var result = cmp()
    if result is RenERR:
        return result
    
    var node = result.value
    while self.current_token.is_type(RenToken.EXACT):
        var token = self.current_token
        result = eat(RenToken.EXACT)
        if result is RenERR:
            return result
        result = cmp()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)
    
    return RenOK.new(node)


func band() -> RenResult:
    var result = exact()
    if result is RenERR:
        return result
    
    var node = result.value
    while self.current_token.is_type(RenToken.BAND):
        var token = self.current_token
        result = eat(RenToken.BAND)
        if result is RenERR:
            return result
        result = exact()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)
    
    return RenOK.new(node)


func xor() -> RenResult:
    var result = band()
    if result is RenERR:
        return result
    
    var node = result.value
    while self.current_token.is_type(RenToken.XOR):
        var token = self.current_token
        result = eat(RenToken.XOR)
        if result is RenERR:
            return result
        result = band()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)
    
    return RenOK.new(node)


func bor() -> RenResult:
    var result = xor()
    if result is RenERR:
        return result
    
    var node = result.value
    while self.current_token.is_type(RenToken.BOR):
        var token = self.current_token
        result = eat(RenToken.BOR)
        if result is RenERR:
            return result
        result = xor()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)
    
    return RenOK.new(node)


func land() -> RenResult:
    var result = bor()
    if result is RenERR:
        return result
    
    var node = result.value
    while self.current_token.is_type(RenToken.AND):
        var token = self.current_token
        result = eat(RenToken.AND)
        if result is RenERR:
            return result
        result = bor()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)
    
    return RenOK.new(node)


func expr() -> RenResult:
    var result = land()
    if result is RenERR:
        return result
    
    var node = result.value
    while self.current_token.is_type(RenToken.OR):
        var token = self.current_token
        result = eat(RenToken.OR)
        if result is RenERR:
            return result
        result = land()
        if result is RenERR:
            return result
        
        node = RenBinOp.new(node, token, result.value)
    
    return RenOK.new(node)


func variable() -> RenResult:
    var token = self.current_token
    var res = eat(RenToken.ID)
    if res is RenERR:
        return res
    var var_obj = RenVar.new(token)
    
    while self.current_token.is_type([RenToken.LBRACK, RenToken.LPAREN]):
        token = self.current_token
        
        var current_namespace = var_obj
        
        res = eat([RenToken.LBRACK, RenToken.LPAREN])
        if res is RenERR:
            return res
        
        match token.token_type:
            
            # Function call
            RenToken.LPAREN:
                var invoke_obj = RenInvoke.new()
                invoke_obj.add_child(current_namespace)
                
                res = comma_separated_exprs(RenToken.RPAREN)
                if res is RenERR:
                    return res
                
                for i in res.value:
                    invoke_obj.add_child(i)
                
                res = eat(RenToken.RPAREN)
                if res is RenERR:
                    return res

                var_obj = invoke_obj
            
            # Key access
            RenToken.LBRACK:
                res = expr()
                if res is RenERR:
                    return res

                var_obj = RenKeyAccess.new(current_namespace, res.value)
                res = eat(RenToken.RBRACK)
                if res is RenERR:
                    return res

    return RenOK.new(var_obj)


func assignment() -> RenResult:
    var res = variable()
    if res is RenERR:
        return res
    
    var id = res.value
    
    var op = self.current_token
    res = eat(RenToken.EQUAL)
    if res is RenERR:
        return res

    res = expr()
    if res is RenERR:
        return res
    else:
        return RenOK.new(RenBinOp.new(id, op, res.value))

# End of Expression parsing frunctions

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


func ifcase() -> RenResult:
    eat(RenToken.IF)
    var ic = RenIfCase.new()

    var res = expr()
    if res is RenERR:
        return res
    
    var condition = res.value
    eat_chain([RenToken.COLON, RenToken.EOL])
    
    res = compound()
    if res is RenERR:
        return res
    
    var outcome = res.value
    
    ic.add_child(RenCondition.new(condition, outcome))
    skip_lines()

    while self.current_token.is_type(RenToken.ELIF):
        res = eat(RenToken.ELIF)
        if res is RenERR:
            return res
        res = expr()
        if res is RenERR:
            return res
        condition = res.value

        res = eat_chain([RenToken.COLON, RenToken.EOL])
        if res is RenERR:
            return res
        
        res = compound()
        if res is RenERR:
            return res
        
        outcome = res.value

        ic.add_child(RenCondition.new(condition, outcome))
        skip_lines()
    
    if self.current_token.is_type(RenToken.ELSE):
        res = eat(RenToken.ELSE)
        if res is RenERR:
            return res
    
        condition = RenBool.new(RenToken.new(RenToken.BOOL, true))

        res = eat_chain([RenToken.COLON, RenToken.EOL])
        if res is RenERR:
            return res
        
        res = compound()
        if res is RenERR:
            return res
        
        outcome = res.value

        ic.add_child(RenCondition.new(condition, outcome))
        skip_lines()
    
    return RenOK.new(ic)


func statement() -> RenResult:
    skip_lines()
    var node = null
    match self.current_token.token_type:
        RenToken.DEFINE, RenToken.DEFAULT, RenToken.REASSIGN:
            var token = self.current_token
            var res = eat([RenToken.DEFINE, RenToken.DEFAULT, RenToken.REASSIGN])
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
        RenToken.IF:
            var res = ifcase()
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
           return error(RenERR.TOKEN_UNEXPECTED, 'Unexpeced token: \"%s\".' % [self.current_token.token_type])
    return RenOK.new(node)


func compound() -> RenResult:
    skip_lines()
    var result = eat(RenToken.BLOCK_START)
    if result is RenERR:
        return result

    var node = RenCompound.new()
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
    
    emit_signal('ast_built', node)
    return RenOK.new(node)
