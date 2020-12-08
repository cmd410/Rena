extends RenAST
class_name RenKeyAccess


func _init(obj: RenAST, key: RenAST):
    add_child(obj)
    add_child(key)


func _to_string():
    return 'KeyAccess'


func visit(interp):

    var obj = get_child(0).visit(interp)
    var key = get_child(1).visit(interp)

    return obj[key]
