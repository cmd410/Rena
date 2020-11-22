extends RenCompound
class_name RenMenuOption

var prompt: RenString

func _init(p: RenString, c: RenCompound):
    prompt = p
    add_child(c)
