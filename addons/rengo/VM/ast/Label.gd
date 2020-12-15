extends RenAST
class_name RenLabel


func _init(token: RenToken):
    self.token = token
    self.id = token.value


func _to_string():
    return 'Label(%s)' % [self.id]


func visit(interp):
    var compound = get_child(0)

    var result = compound.visit(interp)
    
    if result is GDScriptFunctionState and result.is_valid():
        yield(result, 'completed')
