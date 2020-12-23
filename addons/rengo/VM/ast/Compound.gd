extends RenAST
class_name RenCompound


var labels: Dictionary = {}
var current_progress: int = 0


func _to_string():
    return 'Compound<%s>' % [get_child_count()]


func find_labels(interp):
    var i = 0
    for child in get_children():
        if child is RenLabel:
            labels[child.id] = i
        i += 1
    interp.label_stack.append(labels)


func visit(interp):
    
    find_labels(interp)
    
    while self.current_progress < get_child_count():
        var child = get_child(self.current_progress)
        var result = child.visit(interp)
        if result is GDScriptFunctionState and result.is_valid():
            yield(result, 'completed')
        
        self.current_progress += 1
    
    interp.label_stack.pop_back()


func compiled(compiler, offset: int) -> PoolByteArray:
    var bytes_io = StreamPeerBuffer.new()
    
    for i in get_children():
        
        var compiled_statement = i.compiled(compiler, offset)
        offset += len(compiled_statement)

        bytes_io.put_data(compiled_statement)

        if i is RenInvoke:
            bytes_io.put_8(compiler.BCode.POP_TOP)
            offset += 1
    
    return bytes_io.data_array
