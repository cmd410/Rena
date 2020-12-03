extends RenAST
class_name RenCompound


func _to_string():
    return 'Compound<%s>' % [get_child_count()]
