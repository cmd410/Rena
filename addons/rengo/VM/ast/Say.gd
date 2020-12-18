extends RenAST
class_name RenSay


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


func compiled(compiler, offset: int, jump_table: Dictionary = {}) -> PoolByteArray:
    # TODO check compilation to be correct
    # TODO calculate offset 
    var bytes_io = StreamPeerBuffer.new()
    
    # Put say data
    for i in get_children():
        i.compiled(compiler, offset, jump_table)
    
    # Put say statement
    bytes_io.put_8(compiler.BCode.SAY)
    bytes_io.put_u32(get_child_count())
    
    return bytes_io.data_array