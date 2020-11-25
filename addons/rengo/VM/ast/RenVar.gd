extends RenValue
class_name RenVar


func _init(t).(t):
    pass


func _to_string():
    return 'Var<%s>' % [self.value]
