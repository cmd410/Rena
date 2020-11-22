extends RenAST
class_name RenSay


func _init(what: RenAST, who: RenString):
    add_child(what)
    add_child(who)
