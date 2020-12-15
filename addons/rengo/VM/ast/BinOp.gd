extends RenAST
class_name RenBinOp

var token_map = {
        RenToken.PLUS: RenCompiler.BCode.ADD,
        RenToken.MINUS: RenCompiler.BCode.SUB,
        RenToken.MUL: RenCompiler.BCode.MUL,
        RenToken.DIV: RenCompiler.BCode.DIV,
        RenToken.FLOORDIV: RenCompiler.BCode.FLOORDIV,
        RenToken.MOD: RenCompiler.BCode.MOD,
        RenToken.POW: RenCompiler.BCode.POW,
        RenToken.LSHIFT: RenCompiler.BCode.LSHIFT,
        RenToken.RSHIFT: RenCompiler.BCode.RSHIFT,
        RenToken.XOR: RenCompiler.BCode.XOR,
        RenToken.BOR: RenCompiler.BCode.BOR,
        RenToken.BAND: RenCompiler.BCode.BAND,
        RenToken.EXEQ: RenCompiler.BCode.EXEQ,
        RenToken.NOEQ: RenCompiler.BCode.NOEQ,
        RenToken.LESS: RenCompiler.BCode.LESS,
        RenToken.GREATER: RenCompiler.BCode.GREATER,
        RenToken.LEQ: RenCompiler.BCode.LEQ,
        RenToken.GEQ: RenCompiler.BCode.GEQ,
        RenToken.AND: RenCompiler.BCode.AND,
        RenToken.OR: RenCompiler.BCode.OR
    }


func _init(left: RenAST, token: RenToken, right: RenAST):
    self.token = token
    add_child(left)
    add_child(right)


func is_constant():
    return get_child(0).is_constant() and get_child(1).is_constant()


func _to_string():
    return 'BinOp<%s>' % [self.token.token_type]


func visit(interp):
    var left = get_child(0).visit(interp)
    var right = get_child(1).visit(interp)
    match self.token.token_type:
        RenToken.PLUS:
            return left + right
        RenToken.MINUS:
            return left - right
        RenToken.MUL:
            return left * right
        RenToken.DIV:
            return left / right
        RenToken.FLOORDIV:
            return floor(left / right)
        RenToken.MOD:
            return left % right
        RenToken.POW:
            return pow(left, right)
        RenToken.LSHIFT:
            return left << right
        RenToken.RSHIFT:
            return left >> right
        RenToken.XOR:
            return left ^ right
        RenToken.BOR:
            return left | right
        RenToken.BAND:
            return left & right
        RenToken.EXEQ:
            return left == right
        RenToken.NOEQ:
            return left != right
        RenToken.LESS:
            return left < right
        RenToken.GREATER:
            return left > right
        RenToken.LEQ:
            return left <= right
        RenToken.GEQ:
            return left >= right
        RenToken.AND:
            return left and right
        RenToken.OR:
            return left or right
        _:
            assert(false, 'Unknown token for Binary Operation: \"%s\"' % [self.token.token_type])
        

func compiled(compiler):
    if is_constant():
        var value = visit(null)
        compiler.store_constant(value)
    else:
        get_child(0).compiled(compiler)
        get_child(1).compiled(compiler)
        var op = token_map[self.token.token_type]
        compiler.file.store_8(op)
