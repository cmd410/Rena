extends RenAST
class_name RenCompound


func _to_string():
    return 'Compound<%s>' % [get_child_count()]


func visit(interp):
    for child in self.get_children():
        child.visit(interp)
