extends RenAST
class_name RenCondition


func _init(condition: RenAST, compound: RenAST):
    add_child(condition)
    add_child(compound)


func _to_string():
    return 'Condition'


func check(interp) -> bool:
    return bool(get_child(0).visit(interp))


func visit(interp):
    var result = get_child(1).visit(interp)
    if result is GDScriptFunctionState and result.is_valid():
        yield(result, 'completed')


func compiled(compiler, offset: int) -> PoolByteArray:
    # TODO check compilation to be correct
    # TODO calculate offset 
    # TODO actual compilation
    var bytes_io = StreamPeerBuffer.new()
    return bytes_io.data_array
