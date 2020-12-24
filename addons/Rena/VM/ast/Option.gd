extends "AST.gd"



func _init(token):
    self.token = token
    self.id = token.value


func _to_string():
    return 'Option(\"%s\")' % [self.id]
