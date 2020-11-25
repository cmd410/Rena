extends RenValue
class_name RenString


func _init(t).(t):
    pass


func _to_string():
    return 'String<%s>' % [self.value]
