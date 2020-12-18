extends RenAST
class_name RenIfCase


func _to_string():
    return 'IfCase'


func visit(interp):
    var condition_nodes = get_children()

    for con_node in condition_nodes:
        if con_node.check(interp):
            var result = con_node.visit(interp)
            if result is GDScriptFunctionState and result.is_valid():
                yield(result, 'completed')
            break


func compiled(compiler, offset: int) -> PoolByteArray:
    # TODO check compilation to be correct
    # TODO calculate offset 
    # TODO actual compilation
    var bytes_io = StreamPeerBuffer.new()
    for child in get_children():
        bytes_io.put_data(child.compiled(compiler, offset))
    return bytes_io.data_array
