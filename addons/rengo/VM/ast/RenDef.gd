extends RenAST
class_name RenDef


func _init(token: RenToken):
    self.token = token


func _to_string():
    return '%s' % [self.token.token_type]
