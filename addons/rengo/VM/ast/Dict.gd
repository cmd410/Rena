extends RenValue
class_name RenDict


func _init(t).(t):
    pass


func _to_string():
    return 'Dict<%s>' % [get_child_count()]


func visit(interp):
    var d = {}
    for child in get_children():
        var item = child.visit(interp)
        var key = item[0]
        var value = item[1]
        d[key] = value
    return d


func compiled(compiler, offset: int) -> PoolByteArray:
    
    var bytes_io = StreamPeerBuffer.new()
    
    for dict_item in get_children():
        
        var key = dict_item.get_child(0).compiled(compiler, offset)
        offset += len(key)
        
        var value = bytes_io.put_data(dict_item.get_child(1).compiled(compiler, offset))
        offset += len(value)

        bytes_io.put_data(key)
        bytes_io.put_data(value)
    
    bytes_io.put_8(compiler.BCode.BUILD_DICT)
    bytes_io.put_u32(get_child_count())
    
    return bytes_io.data_array
