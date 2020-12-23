extends RenAST
class_name RenOption


func _init(token):
    self.token = token
    self.id = token.value


func _to_string():
    return 'Option(\"%s\")' % [self.id]
