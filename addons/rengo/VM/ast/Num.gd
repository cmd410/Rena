extends RenValue
class_name RenNum


func _init(t).(t):
    pass


func _to_string():
    return 'Num<%s>' % [self.value]


func is_constant() -> bool:
    return true


func compiled(compiler):
    compiler.put_constant(self.value)
