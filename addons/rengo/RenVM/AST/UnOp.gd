extends RenAST
class_name RenUnOp


var token: RenToken = null


func _init(t: RenToken, right: RenAST):
    token = t as RenToken
    add_child(right)
