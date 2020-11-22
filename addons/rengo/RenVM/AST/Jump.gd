extends RenAST
class_name RenJump



func _init(dest: RenVar):
    add_child(dest)
