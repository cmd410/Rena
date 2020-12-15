extends RenValue
class_name RenBool


func _init(t).(t):
    pass


func _to_string():
    return 'Bool<%s>' % [self.value]


func is_constant() -> bool:
    return true


func compiled(compiler):
    compiler.store_constant(self.value)
