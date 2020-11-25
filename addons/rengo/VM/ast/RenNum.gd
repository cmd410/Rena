extends RenValue
class_name RenNum


func _init(t).(t):
    pass


func _to_string():
    return 'Num<%s>' % [self.value]
