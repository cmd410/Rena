extends "AST.gd"



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


func compiled(compiler, offset: int) -> PoolByteArray:
    var bytes_io = StreamPeerBuffer.new()
    var assign = get_child(0)
    
    # Put value bytecode
    var value_data_array = assign.get_child(1).compiled(compiler, offset)
    bytes_io.put_data(value_data_array)
    
    # Put assign statement
    match self.token.token_type:
        RenToken.DEFINE:
            bytes_io.put_8(compiler.BCode.ASSIGN_NAME)
        RenToken.REASSIGN:
            bytes_io.put_8(compiler.BCode.ASSIGN_IF_EXISTS)
        RenToken.DEFAULT:
            bytes_io.put_8(compiler.BCode.ASSIGN_IF_NONE)
    
    bytes_io.put_data(assign.get_child(0).compile_name())
    
    return bytes_io.data_array
