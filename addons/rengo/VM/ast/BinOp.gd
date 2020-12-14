extends RenAST
class_name RenBinOp


func _init(left: RenAST, token: RenToken, right: RenAST):
    self.token = token
    add_child(left)
    add_child(right)


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
    var op = null
    match self.token.token_type:
        RenToken.PLUS:
            op = compiler.BCode.ADD
        RenToken.MINUS:
            op = compiler.BCode.SUB
        RenToken.MUL:
            op = compiler.BCode.MUL
        RenToken.DIV:
            op = compiler.BCode.DIV
        RenToken.FLOORDIV:
            op = compiler.BCode.FLOORDIV
        # TODO implement other ops
        #RenToken.MOD:
        #    op = compiler.BCode.
        #RenToken.POW:
        #    op = compiler.BCode.
        #RenToken.LSHIFT:
        #    op = compiler.BCode.
        #RenToken.RSHIFT:
        #    op = compiler.BCode.
        #RenToken.XOR:
        #    op = compiler.BCode.
        #RenToken.BOR:
        #    op = compiler.BCode.
        #RenToken.BAND:
        #    op = compiler.BCode.
        #RenToken.EXEQ:
        #    op = compiler.BCode.
        #RenToken.NOEQ:
        #    op = compiler.BCode.
        #RenToken.LESS:
        #    op = compiler.BCode.
        #RenToken.GREATER:
        #    op = compiler.BCode.
        #RenToken.LEQ:
        #    op = compiler.BCode.
        #RenToken.GEQ:
        #    op = compiler.BCode.
        #RenToken.AND:
        #    op = compiler.BCode.
        #RenToken.OR:
        #    op = compiler.BCode.

    compiler.file.store_8(op)
