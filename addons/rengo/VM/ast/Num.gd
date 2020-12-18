extends RenValue
class_name RenNum


func _init(t).(t):
    pass


func _to_string():
    return 'Num<%s>' % [self.value]


func is_constant() -> bool:
    return true


func compiled(compiler, _offset: int) -> PoolByteArray:
    var bytes_io = StreamPeerBuffer.new()
    compiler.put_constant(self.value, bytes_io)
    return bytes_io.data_array