extends RenValue
class_name RenDict


func _init(t).(t):
    pass


func _to_string():
    return 'Dict<%s>' % [get_child_count()]


func visit(interp):
    var d = {}
    for child in get_children():
        var item = child.visit(interp)
        var key = item[0]
        var value = item[1]
        d[key] = value
    return d
