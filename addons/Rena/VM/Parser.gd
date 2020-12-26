extends "internal/Ref.gd"


signal exception(err)
signal ast_built(ast)

const RenResult = preload('internal/Result.gd')
const RenOK = preload('internal/OK.gd')
const RenERR = preload('internal/ERR.gd')
const RenToken = preload('internal/Token.gd')

const RenLexer = preload('Lexer.gd')

var lexer: RenLexer = null
var current_token: RenToken = null

# preload AST nodes classes
const AST =       preload('ast/AST.gd')
const BinOp =     preload("ast/BinOp.gd")
const Bool =      preload("ast/Bool.gd")
const Call =      preload("ast/Call.gd")
const Compound =  preload("ast/Compound.gd")
const Condition = preload("ast/Contition.gd")
const Def =       preload("ast/Def.gd")
const Dict =      preload("ast/Dict.gd")
const DictItem =  preload("ast/DictItem.gd")
const IfCase =    preload("ast/IfCase.gd")
const Invoke =    preload("ast/Invoke.gd")
const Jump =      preload("ast/Jump.gd")
const KeyAccess = preload("ast/KeyAccess.gd")
const Label =     preload("ast/Label.gd")
const List =      preload("ast/List.gd")
const Menu =      preload("ast/Menu.gd")
const Num =       preload("ast/Num.gd")
const Option =    preload("ast/Option.gd")
const Return =    preload("ast/Return.gd")
const Say =       preload("ast/Say.gd")
const Str =       preload("ast/String.gd")
const UnOp =      preload("ast/UnOp.gd")
const Value =     preload("ast/Value.gd")
const Var =       preload("ast/Var.gd")


func _init(lexer: RenLexer):
    self.lexer = lexer as RenLexer
    self.current_token = lexer.get_next_token().value
    assert(self.lexer != null, 'Parser needs a valid lexer!')


func error(err_type: String, message: String) -> RenERR:
    var err = self.lexer.error(err_type, message)
    emit_signal('exception', err)
    return err


func eat(token_type) -> RenResult:
    # Consumes Token of given token_type and gets new token
    # Returns RenOK on success and RenERR if token_type does not match
    if self.current_token.is_type(token_type):
        self.current_token = self.lexer.get_next_token().value
        return RenOK.new(0)
    else:
        return error(
            RenERR.TOKEN_UNEXPECTED,
            'Got unexpected token: %s, but must be %s' % [self.current_token, token_type]
        )


func eat_chain(chain: Array) -> RenResult:
    # Same as eat but eats token chains
    for t in chain:
        eat(t).value
    return RenOK.new(0)


func skip_lines():
    while self.current_token.token_type == RenToken.EOL:
        eat(RenToken.EOL).value


func list() -> RenResult:
    var node = List.new(self.current_token)
    eat(RenToken.LBRACK).value

    skip_lines()
    while self.current_token.token_type != RenToken.RBRACK:
        var value = expr().value
        node.add_child(value)
        skip_lines()
        if self.current_token.is_type(RenToken.COMMA):
            eat(RenToken.COMMA).value
            skip_lines()
        elif self.current_token.is_type(RenToken.RBRACK):
            break
        else:
            return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected token while parsing list: %s' % [self.current_token.token_type])
    eat(RenToken.RBRACK).value
    
    return RenOK.new(node)


func dict() -> RenResult:
    # Create new dict AST item
    var node = Dict.new(self.current_token)
    eat(RenToken.LCURL).value
    
    skip_lines()
    while self.current_token.token_type != RenToken.RCURL:
        # Parse dict key
        var key = expr().value
        # key: value separator
        eat(RenToken.COLON).value
        
        # Parse dict value
        var value = expr().value
        # Add DictItem
        node.add_child(DictItem.new(key, value))
        skip_lines()
        # After each item we expect either a comma or closing curly bracket
        if self.current_token.is_type(RenToken.COMMA):
            eat(RenToken.COMMA).value
            skip_lines()
        elif self.current_token.is_type(RenToken.RCURL):
            break
        else:
            return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected token while parsing dictionary: %s' % [self.current_token.token_type])
    # Eat closing curly bracket
    eat(RenToken.RCURL).value
    
    return RenOK.new(node)


func comma_separated_exprs(stop_token) -> RenResult:
    # Returns expression separated by commas as an Array
    # Until stop_token is met, does not eat stop_token tho
    # example:
    # 1, "string", 1+2, varibale
    var values = []
    while not self.current_token.is_type(stop_token):
        var res = expr()
        values.append(res.value)
        if self.current_token.is_type(stop_token):
            break
        else:
            eat(RenToken.COMMA).value
    
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
                node = Num.new(token)
                eat(RenToken.DATA_UNIT).value
            
            RenToken.BOOL:
                node = Bool.new(token)
                eat(RenToken.DATA_UNIT).value
            
            RenToken.STR:
                node = Str.new(token)
                eat(RenToken.DATA_UNIT).value
            
            RenToken.ID:
                node = variable().value
            _:
                return error(
                    RenERR.CODING_ERROR,
                    'Unmathced data unit type %s in factor function.' % [token]
                )
        
        # Power operation should be first to apply
        if self.current_token.token_type == RenToken.POW:
            token = self.current_token
            eat(RenToken.POW).value
            return RenOK.new(BinOp.new(node, token, factor().value))
        return RenOK.new(node)
    
    # Parse Unary Operators
    elif self.current_token.is_type([RenToken.PLUS, RenToken.MINUS, RenToken.NOT]):
        var token = self.current_token
        eat([RenToken.PLUS, RenToken.MINUS, RenToken.NOT]).value
        var res = factor()
        return RenOK.new(UnOp.new(token, res.value))
    # Parse expressions in parenthesis
    elif self.current_token.token_type == RenToken.LPAREN:
        eat(RenToken.LPAREN).value
        var node = expr().value
        eat(RenToken.RPAREN).value
        
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
    var node = factor().value
    while self.current_token.is_type(RenToken.TERM):
        var token = self.current_token
        eat(RenToken.TERM).value
        node = BinOp.new(node, token, factor().value)
    return RenOK.new(node)


func arithm() -> RenResult:
    var node = term().value
    while self.current_token.is_type(RenToken.ARITHM):
        var token = self.current_token
        eat(RenToken.ARITHM).value
        node = BinOp.new(node, token, term().value)
    return RenOK.new(node)


func shifts() -> RenResult:
    var node = arithm().value
    while self.current_token.is_type(RenToken.SHIFTS):
        var token = self.current_token
        eat(RenToken.SHIFTS).value
        node = BinOp.new(node, token, arithm().value)
    return RenOK.new(node)


func cmp() -> RenResult:
    var node = shifts().value
    while self.current_token.is_type(RenToken.CMP):
        var token = self.current_token
        eat(RenToken.CMP).value
        node = BinOp.new(node, token, shifts().value)
    return RenOK.new(node)


func exact() -> RenResult:
    var node = cmp().value
    while self.current_token.is_type(RenToken.EXACT):
        var token = self.current_token
        eat(RenToken.EXACT).value
        node = BinOp.new(node, token, cmp().value)
    return RenOK.new(node)


func band() -> RenResult:
    var node = exact().value
    while self.current_token.is_type(RenToken.BAND):
        var token = self.current_token
        eat(RenToken.BAND).value
        node = BinOp.new(node, token, exact().value)
    return RenOK.new(node)


func xor() -> RenResult:
    var node = band().value
    while self.current_token.is_type(RenToken.XOR):
        var token = self.current_token
        eat(RenToken.XOR).value
        node = BinOp.new(node, token, band().value)
    return RenOK.new(node)


func bor() -> RenResult:
    var node = xor().value
    while self.current_token.is_type(RenToken.BOR):
        var token = self.current_token
        eat(RenToken.BOR).value
        node = BinOp.new(node, token, xor().value)
    return RenOK.new(node)


func land() -> RenResult:
    var node = bor().value
    while self.current_token.is_type(RenToken.AND):
        var token = self.current_token
        eat(RenToken.AND).value
        node = BinOp.new(node, token, bor().value)
    return RenOK.new(node)


func lor() -> RenResult:
    var node = land().value
    while self.current_token.is_type(RenToken.OR):
        var token = self.current_token
        eat(RenToken.OR).value
        node = BinOp.new(node, token, land().value)
    return RenOK.new(node)


func expr() -> RenResult:
    var node = lor().value
    while self.current_token.is_type(RenToken.IN):
        var token = self.current_token
        eat(RenToken.IN).value
        node = BinOp.new(node, token, lor().value)
    return RenOK.new(node)


func variable() -> RenResult:
    # Read ID token
    var token = self.current_token
    eat(RenToken.ID).value
    
    var var_obj = Var.new(token)

    while self.current_token.token_type == RenToken.PERIOD:
        eat(RenToken.PERIOD).value
        var node = variable().value
        if node is Var:
            node.add_child(var_obj)
        elif node is Invoke or node is KeyAccess:
            node.get_child(0).add_child(var_obj)
        var_obj = node

    while self.current_token.is_type([RenToken.LBRACK, RenToken.LPAREN]):
        token = self.current_token
        var current_namespace = var_obj
        eat([RenToken.LBRACK, RenToken.LPAREN]).value
        
        match token.token_type:
            # Function call
            RenToken.LPAREN:
                var invoke_obj = Invoke.new()
                invoke_obj.add_child(current_namespace)
                var values = comma_separated_exprs(RenToken.RPAREN).value
                
                for i in values:
                    invoke_obj.add_child(i)
                eat(RenToken.RPAREN).value

                var_obj = invoke_obj
            # Key access
            RenToken.LBRACK:
                var_obj = KeyAccess.new(current_namespace, expr().value)
                eat(RenToken.RBRACK).value

    return RenOK.new(var_obj)


func assignment() -> RenResult:
    var id = variable().value
    var op = self.current_token
    eat(RenToken.EQUAL).value
    return RenOK.new(BinOp.new(id, op, expr().value))

# End of Expression parsing frunctions
func label() -> RenResult:
    eat(RenToken.LABEL).value
    
    var token = self.current_token

    eat_chain([RenToken.ID, RenToken.COLON, RenToken.EOL]).value

    var node = Label.new(token)
    node.add_child(compound().value)
    return RenOK.new(node)


func say() -> RenResult:
    var tokens: Array = []
    while not self.current_token.token_type in [RenToken.EOL, RenToken.BLOCK_END]:
        match self.current_token.token_type:
            RenToken.ID, RenToken.STR:
                tokens.append(self.current_token)
                eat([RenToken.ID, RenToken.STR]).value
            _:
                return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected token in say statement: %s' % [self.current_token])
    if tokens.empty():
        return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected end of say statement')
    var node = Say.new()
    for token in tokens:
        match token.token_type:
            RenToken.ID:
                node.add_child(Var.new(token))
            RenToken.STR:
                node.add_child(Str.new(token))
    return RenOK.new(node)


func menu() -> RenResult:
    eat_chain([RenToken.MENU, RenToken.COLON, RenToken.EOL]).value
    
    skip_lines()
    eat(RenToken.BLOCK_START).value

    var token = self.current_token
    eat(RenToken.STR).value
    
    var menu = null
    # Parsing first menu option or line
    match self.current_token.token_type:
        RenToken.EOL:
            menu = Menu.new(token.value)
            eat(RenToken.EOL).value
        RenToken.COLON, RenToken.IF:
            var option = Option.new(token)
            
            if self.current_token.is_type(RenToken.IF):
                eat(RenToken.IF).value
                var condition = expr().value
                option.add_child(condition)

            menu = Menu.new()
            menu.add_child(option)
            eat(RenToken.COLON).value
            eat(RenToken.EOL).value
            skip_lines()
            option.add_child(compound().value)
        _:
            return error(
                RenERR.TOKEN_UNKNOWN,
                'Unexpected token while parsing menu: %s' % [self.current_token]
                )
    skip_lines()
    
    while self.current_token.token_type == RenToken.STR:
        token = self.current_token
        eat(RenToken.STR).value
        
        var option = Option.new(token)
        if self.current_token.is_type(RenToken.IF):
            eat(RenToken.IF).value
            var condition = expr().value
            option.add_child(condition)

        eat_chain([RenToken.COLON, RenToken.EOL])

        skip_lines()
        
        option.add_child(compound().value)
        menu.add_child(option)
        skip_lines()
    
    eat(RenToken.BLOCK_END).value
    return RenOK.new(menu)


func ifcase() -> RenResult:
    eat(RenToken.IF).value
    var ic = IfCase.new()
    var condition = expr().value
    eat_chain([RenToken.COLON, RenToken.EOL])
    var outcome = compound().value
    ic.add_child(Condition.new(condition, outcome))
    skip_lines()
    while self.current_token.is_type(RenToken.ELIF):
        eat(RenToken.ELIF).value
        condition = expr().value
        eat_chain([RenToken.COLON, RenToken.EOL]).value
        
        outcome = compound().value
        ic.add_child(Condition.new(condition, outcome))
        skip_lines()
    if self.current_token.is_type(RenToken.ELSE):
        eat(RenToken.ELSE).value
    
        condition = Bool.new(RenToken.new(RenToken.BOOL, true))
        eat_chain([RenToken.COLON, RenToken.EOL]).value
        
        outcome = compound().value
        ic.add_child(Condition.new(condition, outcome))
        skip_lines()
    return RenOK.new(ic)


func statement() -> RenResult:
    skip_lines()
    var node = null
    match self.current_token.token_type:
        RenToken.DEFINE, RenToken.DEFAULT, RenToken.REASSIGN:
            var token = self.current_token
            eat([RenToken.DEFINE, RenToken.DEFAULT, RenToken.REASSIGN]).value
            
            node = Def.new(token)
            node.add_child(assignment().value)
        RenToken.LABEL:
            node = label().value
        RenToken.ID, RenToken.STR:
            node = say().value
        RenToken.MENU:
            node = menu().value
        RenToken.IF:
            node = ifcase().value
        RenToken.JUMP:
            eat(RenToken.JUMP).value
            var token = self.current_token
            eat(RenToken.ID).value
            node = Jump.new(token)
        RenToken.CALL:
            eat(RenToken.CALL).value
            var token = self.current_token
            eat(RenToken.ID).value
            node = Call.new(token)
        RenToken.DO:
            eat(RenToken.DO).value
            node = variable().value
        RenToken.RETURN:
            eat(RenToken.RETURN).value
            node = Return.new()
        RenToken.EOL:
            eat(RenToken.EOL).value
        RenToken.BLOCK_END:
            pass
        _:
           return error(RenERR.TOKEN_UNEXPECTED, 'Unexpeced token: \"%s\".' % [self.current_token.token_type])
    return RenOK.new(node)


func compound() -> RenResult:
    skip_lines()
    eat(RenToken.BLOCK_START).value

    var node = Compound.new()
    while self.current_token.token_type != RenToken.BLOCK_END:
        var st = statement().value
        node.add_child(st)
        skip_lines()
    eat(RenToken.BLOCK_END).value
    return RenOK.new(node)


func script():
    if self.current_token == null:
        return error('ParserInitError', 'Parser got no tokens to process.')
    var node = compound().value
    eat(RenToken.EOF).value

    emit_signal('ast_built', node)
    return RenOK.new(node)
