extends RenAST
class_name RenMenu


var prompt = null


func _init(prompt = null):
    self.prompt = prompt


func _to_string():
    if self.prompt == null:
        return 'Menu(%s)' % [get_child_count()]
    else:
        return 'Menu(\"%s\", %s)' % [self.prompt, get_child_count()]
