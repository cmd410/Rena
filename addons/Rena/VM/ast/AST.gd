extends Node


var id = null
var token = null


func is_constant() -> bool:
    return false


func _to_string():
    return 'ASTNode<%s>' % [get_child_count()]


func visit(interp):
    assert(false, 'Visit func is not defined for this node type.')


func compiled(compiler, offset: int) -> PoolByteArray:
    assert(false, 'Compile not implemented for this node')
    return PoolByteArray()
