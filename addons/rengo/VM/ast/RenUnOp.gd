extends RenAST
class_name RenUnOp


func _init(token: RenToken, right: RenAST):
    self.token = token
    add_child(right)

func _to_string():
    return 'UnOp(%s)' % [self.token.token_type]
