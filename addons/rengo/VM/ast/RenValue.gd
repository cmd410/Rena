extends RenAST
class_name RenValue


var value


func _init(token: RenToken):
    self.token = token
    self.value = token.value
