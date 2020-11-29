extends RenAST
class_name RenCondition


func _init(condition: RenAST, compound: RenAST):
    add_child(condition)
    add_child(compound)


func _to_string():
    return 'Condition'
