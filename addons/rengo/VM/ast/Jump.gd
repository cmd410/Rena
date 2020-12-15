extends RenAST
class_name RenJump

var dest: String

func _init(token):
    self.dest = token.value
