extends RenAST
class_name RenDictItem


func _init(key: RenAST, value: RenAST):
    add_child(key)
    add_child(value) 


func _to_string():
    return 'DictItem'


func visit(interp):
    var key = get_child(0).visit(interp)
    var value = get_child(1).visit(interp)
    return [key, value]
