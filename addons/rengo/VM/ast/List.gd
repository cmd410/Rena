extends RenValue
class_name RenList


func _init(t).(t):
    pass


func _to_string():
    return 'List<%s>' % [get_child_count()]


func visit(interp):
    var list = []
    for i in get_children():
        list.append(i.visit(interp))
    return list


func compiled(compiler, offset: int, jump_table: Dictionary = {}) -> PoolByteArray:
    # TODO check compilation to be correct
    # TODO calculate offset 
    var bytes_io = StreamPeerBuffer.new()
    
    # Put array data
    for child in get_children():
        bytes_io.put_data(child.compiled(compiler, offset, jump_table))
    
    # Put build list command
    bytes_io.put_8(compiler.BCode.BUILD_LIST)
    bytes_io.put_32(get_child_count())
    
    return bytes_io.data_array
