extends "AST.gd"



func _to_string():
    if len(get_children()) >= 2:
        return 'Say(%s, \"%s\")' % [get_child(0), get_child(1)]
    return 'Say(\"%s\")' % [get_child(0)]


func visit(interp):
    var who: String = ''
    var what: String = ''
    var ccount = get_child_count()
    
    if ccount == 1:
        what = get_child(0).visit(interp)
        interp.say_statement(who, what)
        yield(interp, 'proceed')
    
    else:
        who = get_child(0).visit(interp)
        for i in range(1, ccount):
            what = get_child(i).visit(interp)
            interp.say_statement(who, what)
            yield(interp, 'proceed')


func compiled(compiler, offset: int) -> PoolByteArray:
    var bytes_io = StreamPeerBuffer.new()
    
    # Put say data
    for child in get_children():
        var compiled_item = child.compiled(compiler, offset)
        offset += len(compiled_item)
        bytes_io.put_data(compiled_item)
    
    # Put say statement
    bytes_io.put_8(compiler.BCode.SAY)
    bytes_io.put_u32(get_child_count())
    
    return bytes_io.data_array
