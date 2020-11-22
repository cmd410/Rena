extends RenCompound
class_name RenLabel


var label_name: RenVar = null


func _init(name: RenVar):
    label_name = name


func set_compound(compound: RenCompound):
    add_child(compound)
