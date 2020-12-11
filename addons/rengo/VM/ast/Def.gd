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
            if interp.defines.has(name):
                assert(false, 'Name \"%s\" is already hard defined.' % [name])
            if not interp.defaults.has(name):
                interp.defaults[name] = value
        RenToken.DEFINE:
            if interp.defaults.has(name):
                assert(false, 'Name \"%s\" is already defined as default.' % [name])
            interp.defines[name] = value
        RenToken.REASSIGN:
            if interp.defines.has(name):
                interp.defines[name] = value
            elif interp.defaults.has(name):
                interp.defaults[name] = value
            else:
                assert(false, 'Name \"%s\" is not defined.' % [name])
    interp.state_change()
