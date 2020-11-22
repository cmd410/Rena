extends RenAST
class_name RenAssign

var token: RenToken

func _init(l: RenVar, t: RenToken, r: RenAST):
    token = t
    add_child(l)
    add_child(r)
