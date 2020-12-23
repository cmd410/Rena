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
    var start_offset = offset
    var bytes_io = StreamPeerBuffer.new()

    var pending_jumps: PoolIntArray = []

    for i in range(get_child_count()):
        var child = get_child(i)
        var compiled_branch = child.compiled(compiler, offset)
        offset += len(compiled_branch)
        bytes_io.put_data(compiled_branch)
        pending_jumps.append(offset - 4 - start_offset)

    # insert jumps to if end for all intermediate branches
    for idx in pending_jumps:
        bytes_io.seek(idx)
        bytes_io.put_u32(offset)

    return bytes_io.data_array
