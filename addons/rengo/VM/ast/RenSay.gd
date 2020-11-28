extends RenAST
class_name RenSay


func _to_string():
    if len(get_children()) >= 2:
        return 'Say(%s, \"%s\")' % [get_child(0), get_child(1)]
    return 'Say(\"%s\")' % [get_child(0)]
