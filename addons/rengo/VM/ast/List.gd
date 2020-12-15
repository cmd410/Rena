extends RenValue
class_name RenList


func _init(t).(t):
    pass


func _to_string():
    return 'List<%s>' % [get_child_count()]


func visit(interp):
    var list = []
    for i in get_children():
        list.append(i.visit(interp))
    return list


func compiled(compiler):
    for i in get_children():
        i.compiled(compiler)
    compiler.add_byte(compiler.BCode.BUILD_LIST)
