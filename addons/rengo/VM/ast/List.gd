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


func compiled(compiler, offset: int) -> PoolByteArray:
    var bytes_io = StreamPeerBuffer.new()
    
    # Put array data
    for child in get_children():
        var list_item = child.compiled(compiler, offset)
        offset += len(list_item)
        bytes_io.put_data(list_item)
    
    # Put build list command
    bytes_io.put_8(compiler.BCode.BUILD_LIST)
    bytes_io.put_32(get_child_count())
    
    return bytes_io.data_array
