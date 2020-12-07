extends RenAST
class_name RenInvoke


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
