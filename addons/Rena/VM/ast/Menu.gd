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

    var local_offset = 0
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
    if prompt is String:
        bytes_io.put_utf8_string(prompt)
    else:
        bytes_io.put_utf8_string('')

    var terminal_jumps = []
    
    local_offset += bytes_io.get_size()

    for option in options:
        var op_id = option.id
        var compound = option.get_child(0)
        var option_offset = offset + local_offset
        
        # Put option offset into jump table
        bytes_io.seek(pending_jump_options[op_id])
        bytes_io.put_u32(option_offset)
        bytes_io.seek(local_offset)

        # Compile option body
        var compiled_branch = compound.compiled(compiler, option_offset)
        bytes_io.put_data(compiled_branch)
        local_offset += len(compiled_branch)
        bytes_io.put_8(compiler.BCode.JUMP)
        local_offset += 1
        terminal_jumps.append(local_offset)
        bytes_io.put_u32(0)  # Placeholder u32 jump index to menu end
        local_offset += 4
    
    # Put jumps to menu end
    for i in terminal_jumps:
        bytes_io.seek(i)
        bytes_io.put_u32(offset + bytes_io.get_size())

    return bytes_io.data_array
