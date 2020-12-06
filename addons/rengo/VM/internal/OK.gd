extends RenResult
class_name RenOK


var value


func _init(value=null):
    self.value = value


func _to_string():
    return 'OK(%s)' % [self.value]
