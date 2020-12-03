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
        
