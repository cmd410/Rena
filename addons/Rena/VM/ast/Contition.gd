extends "AST.gd"


func _init(condition, compound):
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
    var bytes_io = StreamPeerBuffer.new()
    
    var compiled_condition = get_child(0).compiled(compiler, offset)
    bytes_io.put_data(compiled_condition)
    bytes_io.put_8(compiler.BCode.JUMP_IF_FALSE)
    var branch_offset = offset + len(compiled_condition) + 5

    var compiled_branch = get_child(1).compiled(compiler, branch_offset)
    
    offset = branch_offset + len(compiled_branch)

    bytes_io.put_u32(offset+5)

    bytes_io.put_data(compiled_branch)
    bytes_io.put_8(compiler.BCode.JUMP)
    bytes_io.put_u32(0)

    return bytes_io.data_array
