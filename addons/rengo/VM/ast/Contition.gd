extends RenAST
class_name RenCondition


func _init(condition: RenAST, compound: RenAST):
    add_child(condition)
    add_child(compound)


func _to_string():
    return 'Condition'


func visit(interp):
    if not get_child(0).visit(interp):
        return false
    get_child(1).visit(interp)
    return true
