extends "AST.gd"



func _init(key, value):
    add_child(key)
    add_child(value) 


func _to_string():
    return 'DictItem'


func visit(interp):
    var key = get_child(0).visit(interp)
    var value = get_child(1).visit(interp)
    return [key, value]
