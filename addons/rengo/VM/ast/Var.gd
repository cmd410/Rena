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
    
    # Is inside namespace?
    if get_child_count() > 0:
        var namespace = get_child(0).visit(interp)
        if not namespace.has(var_name()):
            assert(false, '\"%s\" does not has attribute \"%s\"' % [get_child(0).var_name(), var_name()])
        return namespace.get(var_name())
    
    # Not in namespace, get from global scope.
    else:
        if interp.is_name_defined(name):
            return interp.get_name(name)
        else:
            assert(false, 'Name \"%s\" is not defined.' % [name])
