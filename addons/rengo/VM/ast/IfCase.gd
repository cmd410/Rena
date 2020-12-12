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
