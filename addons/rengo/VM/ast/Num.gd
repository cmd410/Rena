extends RenValue
class_name RenNum


func _init(t).(t):
    pass


func _to_string():
    return 'Num<%s>' % [self.value]


func compiled(compiler):
    compiler.add_byte(compiler.BCode.LOAD_CONST)
    if typeof(self.value) == TYPE_INT:
        var dt = compiler.DataTypes
        var type = dt.INT64
        if self.value >= 0:
            if self.value <= pow(2, 8) - 1:
                type = dt.UINT8
            elif self.value <= pow(2, 16) - 1:
                type = dt.UINT16
            elif self.value <= pow(2, 32) - 1:
                type = dt.UINT32
        
        compiler.add_byte(type)
        
        match type:
            dt.UINT8:
                compiler.file.store_8(self.value)
            dt.UINT16:
                compiler.file.store_16(self.value)
            dt.UINT32:
                compiler.file.store_32(self.value)
            dt.INT64:
                compiler.file.store_64(self.value)

    elif typeof(self.value) == TYPE_REAL:
        compiler.add_byte(compiler.DataTypes.FLOAT)
        compiler.file.store_float(self.value)
    
    else:
        assert(false, 'Value of unknown type: %s' % [self.value])
