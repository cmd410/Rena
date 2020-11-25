extends RenAST
class_name RenBinOp


func _init(left: RenAST, token: RenToken, right: RenAST):
    self.token = token
    add_child(left)
    add_child(right)


func _to_string():
    return 'BinOp<%s %s %s>' % [
        get_child(0),
        self.token.token_type,
        get_child(1)
    ]
