extends Node
class_name RenAST


var id = null
var token: RenToken = null


func _to_string():
    return 'ASTNode<%s>' % [get_child_count()]
