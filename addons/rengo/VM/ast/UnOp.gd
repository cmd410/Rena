extends RenAST
class_name RenUnOp


func _init(token: RenToken, right: RenAST):
    self.token = token
    add_child(right)

func _to_string():
    return 'UnOp(%s)' % [self.token.token_type]



func visit(interp):
    match self.token.token_type:
        RenToken.PLUS:
            return +get_child(0).visit(interp)
        RenToken.MINUS:
            return -get_child(0).visit(interp)
        RenToken.NOT:
            return not get_child(0).visit(interp)
        _:
            assert(false, 'Invalid token for Unary operation')
