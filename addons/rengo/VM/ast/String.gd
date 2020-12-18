extends RenValue
class_name RenString


func _init(t).(t):
    pass


func _to_string():
    return 'String<%s>' % [self.value]


func compiled(compiler, offset: int, jump_table: Dictionary = {}) -> PoolByteArray:
    # TODO check compilation to be correct
    # TODO calculate offset 
    var bytes_io = StreamPeerBuffer.new()
    compiler.put_constant(self.value, bytes_io)
    return bytes_io.data_array
