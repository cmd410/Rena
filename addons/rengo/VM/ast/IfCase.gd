extends RenAST
class_name RenIfCase


func _to_string():
    return 'IfCase'


func visit(interp):
    var condition_nodes = get_children()

    for con_node in condition_nodes:
        if con_node.visit(interp):
            break
