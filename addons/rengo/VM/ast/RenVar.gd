extends RenValue
class_name RenVar


func _init(t).(t):
    pass


func _to_string():
    return 'Var<%s>' % [self.value]


func var_name() -> String:
    return self.value


func visit(interp):
    var name = var_name()
    if interp.defines.has(name):
        return interp.defines[name]
    elif interp.defaults.has(name):
        return interp.defaults[name]
    else:
        assert(false, 'Name \"%s\" is not defined.' % [name])
