extends RenAST
class_name RenBinOp


var op: RenToken


func _init(l: RenAST, o: RenToken, r: RenAST):
    op = o
    add_child(l)
    add_child(r)
