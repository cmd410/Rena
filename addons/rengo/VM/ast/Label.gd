extends RenAST
class_name RenLabel


func _init(token: RenToken):
    self.token = token
    self.id = token.value


func _to_string():
    return 'Label(%s)' % [self.id]
