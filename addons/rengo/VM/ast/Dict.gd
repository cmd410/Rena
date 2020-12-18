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


func compiled(compiler, offset: int, jump_table: Dictionary = {}) -> PoolByteArray:
    # TODO check compilation to be correct
    # TODO calculate offset 
    var bytes_io = StreamPeerBuffer.new()
    
    for dict_item in get_children():
        
        bytes_io.put_data(dict_item.get_child(0).compiled(compiler, offset, jump_table))
        bytes_io.put_data(dict_item.get_child(1).compiled(compiler, offset, jump_table))
    
    bytes_io.put_8(compiler.BCode.BUILD_DICT)
    bytes_io.put_u32(get_child_count())
    
    return bytes_io.data_array
