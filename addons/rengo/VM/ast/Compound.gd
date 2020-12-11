extends RenAST
class_name RenCompound


func _to_string():
    return 'Compound<%s>' % [get_child_count()]


func visit(interp):
    for child in self.get_children():
        var result = child.visit(interp)
        if result is GDScriptFunctionState:
            yield(result, 'completed')
