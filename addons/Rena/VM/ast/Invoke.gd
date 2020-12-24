extends "AST.gd"



func _to_string():
    return 'Invoke'


func visit(interp):
    var children = get_children()
    
    var function_reference = children[0].visit(interp) as FuncRef
    assert(function_reference != null, 'Attemped not call non callable object!')

    var args: Array = []

    for i in range(1, len(children)):
        args.append(children[i].visit(interp))

    return function_reference.call_funcv(args)


func compiled(compiler, offset: int) -> PoolByteArray:
    var bytes_io = StreamPeerBuffer.new()

    for i in range(1, get_child_count()):
        var compiled_arg = get_child(i).compiled(compiler, offset)
        offset += len(compiled_arg)
        bytes_io.put_data(compiled_arg)
    
    var compiled_callable = get_child(0).compiled(compiler, offset)
    offset += len(compiled_callable)
    
    bytes_io.put_data(compiled_callable)
    
    bytes_io.put_8(compiler.BCode.CALL_FUNC)
    bytes_io.put_u32(get_child_count() - 1)

    return bytes_io.data_array
