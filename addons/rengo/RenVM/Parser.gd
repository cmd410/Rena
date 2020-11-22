extends Node
class_name RenParser


onready var lexer = get_node("RenLexer") as RenLexer


var current_token: RenToken = null
var ast: RenCompound = null


func init(filename: String):
    lexer.set_source_file(filename)
    current_token = lexer.get_next_token()


func error(msg: String = '') -> void:
    """Raises error with some useful message
    """
    var base_msg = '[ParserError] in file {filename}\n\tLine {lineno}: \"{line}\"'
    if msg != '':
        msg = base_msg+ '\n\t' + msg
    else:
        msg = base_msg

    msg = msg.format({
        'filename': lexer.source_file,
        'line': lexer.current_line,
        'lineno': lexer.line + 1,
        'char': lexer.current_char,
        'pos': lexer.pos
    })

    assert(false, msg)


func eat(token_type: int):
    var token = current_token as RenToken
    if token.token_type & token_type:
        current_token = lexer.get_next_token()
    else:
        error('Unexpected token: \"{char}\" at pos {pos}')


func factor() -> RenAST:
    """Handles numbers and expressions
    """
    var token = self.current_token as RenToken
    if token.token_type & RenToken.types.DT_NUMBER:
        eat(RenToken.types.DT_NUMBER)
        return RenNum.new(token)
    elif token.token_type & RenToken.types.M_ADDITIVE:
        eat(RenToken.types.M_ADDITIVE)
        return RenUnOp.new(token, factor())
    elif token.token_type == RenToken.types.LPAREN:
        eat(RenToken.types.LPAREN)
        var node = expr()
        eat(RenToken.types.RPAREN)
        return node
    else:
        error()
        return null


func term() -> RenAST:
    """Handles multiplication and division
    """
    var node = factor()

    while current_token.token_type & RenToken.types.M_MULTIPLICATIVE:
        var token = current_token
        eat(RenToken.types.M_MULTIPLICATIVE)
        
        node = RenBinOp.new(node, token, factor())
    
    return node


func expr() -> RenAST:
    """Handles summation and substraction operations
    """
    var node = term()

    while current_token.token_type & RenToken.types.M_ADDITIVE:
        var token = current_token
        eat(RenToken.types.M_ADDITIVE)
        node = RenBinOp.new(node, token, term())
    
    return node


func script() -> RenCompound:
    var main: RenCompound = compound_statement()
    eat(RenToken.types.EOF)
    return main


func compound_statement() -> RenCompound:
    """Handles blocks of code
    """
    eat(RenToken.types.BLOCK_START)

    var root: RenCompound = RenCompound.new()
    var nodes: Array = statement_list()

    for node in nodes:
        root.add_child(node)
    
    eat(RenToken.types.BLOCK_END)
    return root


func statement_list() -> Array:

    var node: RenAST = statement()
    var results: Array = [node]

    while true:
        if current_token.token_type in [RenToken.types.EOF, RenToken.types.BLOCK_END]:
            break
        elif current_token.token_type == RenToken.types.IDENTIFIER:
            error()
        
        node = statement()
        results.append(node)
    
    return results


func statement() -> RenAST:
    var node = null
    if current_token.token_type & RenToken.types.KEYWORD:
        
        if current_token.type == RenToken.types.LABEL:
            node = label_statement()
        
        elif current_token.type == RenToken.types.MENU:
            node = menu_statement()
        
        elif current_token.type & RenToken.types.ASSIGN:
            node = assignment_statement()
        
        elif current_token.type == RenToken.types.JUMP:
            node = jump()
        
        #elif current_token.type == RenToken.types.CALL:
        #    node = call()
        
        else:
            error((
                'Unhandled keyword \"%s\", its either plugin bug or this keyword is not implemented yet.' %
                [current_token.value]))
    
    elif current_token.token_type in [RenToken.types.IDENTIFIER, RenToken.types.DT_STRING]:
        var says = say_statement()
        if len(says) > 1:
            node = RenCompound.new()
            for i in says:
                node.add_child(i)
        else:
            node = says[0]
    else:
        error('Could not parse this line for some reason. Most probalby a bug.')
    eol()
    return node


func label_statement() -> RenLabel:
    eat(RenToken.types.K_LABEL)

    var label_name = variable()

    eat(RenToken.types.COLON)

    var node = RenLabel.new(label_name)

    node.set_compound(self.compound_statement())

    return node


func menu_statement() -> RenMenu:
    eat(RenToken.types.K_MENU)
    eat(RenToken.types.COLON)
    eat(RenToken.types.BLOCK_START)
    var node = RenMenu.new()

    var token = current_token
    var caption = make_empty_str()

    if current_token.token_type == RenToken.types.DT_STRING:
        caption = string()
    
    if current_token.token_type == RenToken.types.COLON:
        node.add_child(RenMenuOption.new(caption, compound_statement()))
        caption = make_empty_str()
    
    node.caption = caption

    while current_token.token_type != RenToken.types.BLOCK_END:
        var op_string = string()
        eat(RenToken.types.COLON)
        node.add_child(RenMenuOption.new(op_string, compound_statement()))
    
    return node


func variable() -> RenVar:
    var v = RenVar.new(current_token)
    eat(RenToken.types.IDENTIFIER)
    return v


func assignment_statement():
    var op = current_token
    eat(RenToken.types.DECLARATION)
    
    var v = variable()

    eat(RenToken.types.EQUAL)

    return RenAssign.new(v, op, expr())


func string() -> RenString:
    var s = RenString.new(current_token)
    eat(RenToken.types.DT_STRING)
    return s


func sayer():
    if current_token.token_type == RenToken.types.DT_STRING:
        return string()
    elif current_token.token_type == RenToken.types.IDENTIFIER:
        return variable()


func eol() -> void:
    eat(RenToken.types.EOL)


func make_empty_str() -> RenString:
    return RenString.new(RenToken.new(RenToken.types.DT_STRING, ''))


func say_statement() -> Array:
    var who = sayer()
    var phrases: Array = []
    
    while current_token.token_type != RenToken.types.EOL:
        phrases.append(string())
    
    if phrases.empty():
        phrases.append(who)
        who = make_empty_str()
    
    var says: Array = [] 
    for i in phrases:
        says.append(RenSay.new(i, who))
    
    return says


func jump():
    eat(RenToken.types.K_JUMP)
    var node = RenJump.new(variable())
    return node


func parse():
    if ast != null:
        ast.queue_free()
    ast = script()
    ast.name = 'Script'
    add_child(ast)
    return ast
