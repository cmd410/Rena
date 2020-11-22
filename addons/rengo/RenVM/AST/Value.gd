extends RenAST
class_name RenValue


var token: RenToken
var value


func _init(t):
    token = t
    value = t.value
