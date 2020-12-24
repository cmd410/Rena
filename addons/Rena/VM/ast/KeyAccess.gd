extends "AST.gd"



func _init(obj, key):
    add_child(obj)
    add_child(key)


func _to_string():
    return 'KeyAccess'


func visit(interp):

    var obj = get_child(0).visit(interp)
    var key = get_child(1).visit(interp)

    return obj[key]


func compiled(compiler, offset: int) -> PoolByteArray:
    var bytes_io = StreamPeerBuffer.new()

    bytes_io.put_data(get_child(0).compiled(compiler, offset))
    bytes_io.put_data(get_child(1).compiled(compiler, offset))
    bytes_io.put_8(compiler.BCode.LOAD_KEY)

    return bytes_io.data_array
