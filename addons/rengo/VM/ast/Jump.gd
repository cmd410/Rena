extends RenAST
class_name RenJump


var dest: String


func _init(token):
    self.dest = token.value

func _to_string():
    return 'Jump to %s' % [self.dest]


func compiled(compiler, offset: int) -> PoolByteArray:
    # If we can not find label index now
    # maybe it is defined later
    var target_offset = compiler.jump_table.get(self.dest, -1)
    if target_offset == -1:
        compiler.pending_jumps[offset] = self.dest
        target_offset = 0
    
    var bytes_io = StreamPeerBuffer.new()
    
    bytes_io.put_8(compiler.BCode.JUMP)
    bytes_io.put_u32(target_offset)
    
    return bytes_io.data_array