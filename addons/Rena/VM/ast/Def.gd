extends "AST.gd"


const KeyAccess = preload('KeyAccess.gd')
const RenToken = preload('../internal/Token.gd')


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
    var assign_target = assign.get_child(0)
    var compiled_name = null
    # Put assign statement
    match self.token.token_type:
        RenToken.DEFINE:
            bytes_io.put_8(compiler.BCode.ASSIGN_NAME)
            compiled_name = assign_target.compile_name()
            bytes_io.put_data(compiled_name)
        RenToken.DEFAULT:
            bytes_io.put_8(compiler.BCode.ASSIGN_IF_NONE)
            compiled_name = assign_target.compile_name()
            bytes_io.put_data(compiled_name)
        RenToken.REASSIGN:
            if assign_target is KeyAccess:
                
                # Put data about key namespace
                bytes_io.put_data(
                    assign_target\
                        .get_child(0)\
                        .compiled(compiler,offset + bytes_io.get_size())
                )
                # Put key
                compiled_name = assign_target\
                                    .get_child(1)\
                                    .compiled(compiler, offset + bytes_io.get_size())
                bytes_io.put_data(compiled_name)
                # Put command to set key
                bytes_io.put_8(compiler.BCode.ASSIGN_KEY)

            elif assign_target.get_child_count():
                # Compile attribute namespace
                bytes_io.put_data(assign_target.get_child(0).compiled(compiler, offset + bytes_io.get_size()))
                
                # Put ASSIGN_ATTR <attr_name>
                bytes_io.put_8(compiler.BCode.ASSIGN_ATTR)
                compiled_name = assign_target.compile_name()
                bytes_io.put_data(compiled_name)

            else:
                
                # Regular name reassign
                bytes_io.put_8(compiler.BCode.ASSIGN_IF_EXISTS)
                compiled_name = assign_target.compile_name()
                bytes_io.put_data(compiled_name)
    
    return bytes_io.data_array
