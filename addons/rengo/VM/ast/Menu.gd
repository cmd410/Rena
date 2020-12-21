extends RenAST
class_name RenMenu


var prompt = null


func _init(prompt = null):
    self.prompt = prompt


func _to_string():
    if self.prompt == null:
        return 'Menu(%s)' % [get_child_count()]
    else:
        return 'Menu(\"%s\", %s)' % [self.prompt, get_child_count()]


func compiled(compiler, offset: int) -> PoolByteArray:
    var bytes_io = StreamPeerBuffer.new()

    var options = get_children()

    var pending_jump_options: Dictionary = {}

    # Build jump table
    for option in options:
        compiler.put_constant(option.id, bytes_io)
        bytes_io.put_8(compiler.BCode.LOAD_CONST)
        bytes_io.put_8(compiler.DataTypes.UINT32)
        pending_jump_options[option.id] = bytes_io.get_size()
        bytes_io.put_u32(0)  # Placeholder u32 jump index for option
    
    bytes_io.put_8(compiler.BCode.MENU)
    bytes_io.put_u32(len(options))

    var terminal_jumps = []

    for option in options:
        var op_id = option.id
        var compound = option.get_child(0)
        var option_offset = offset + bytes_io.get_size()
        
        # Put option offset into jump table
        bytes_io.seek(pending_jump_options[op_id])
        bytes_io.put_u32(option_offset)
        bytes_io.seek(option_offset)

        # Compile option body
        bytes_io.put_data(compound.compiled(compiler, option_offset))
        bytes_io.put_8(compiler.BCode.JUMP)
        terminal_jumps.append(bytes_io.get_size())
        bytes_io.put_u32(0)  # Placeholder u32 jump index to menu end
    
    # Put jumps to menu end
    for i in terminal_jumps:
        bytes_io.seek(i)
        bytes_io.put_u32(offset + bytes_io.get_size())

    return bytes_io.data_array
