extends RenAST
class_name RenDef


func _init(token: RenToken):
    self.token = token


func _to_string():
    return '%s' % [self.token.token_type]


func visit(interp):
    var assign = get_child(0)
    var name = assign.get_child(0).var_name()
    var value = assign.get_child(1).visit(interp)
    
    match self.token.token_type:
        RenToken.DEFAULT:
            if not interp.defaults.has(name):
                interp.defaults[name] = value
        RenToken.DEFINE:
            interp.defines[name] = value
