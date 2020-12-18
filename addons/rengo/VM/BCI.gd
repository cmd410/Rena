extends RenRef
class_name RenBCI
# ByteCode Interpreter

var data_stack: Array = []
var globals: Dictionary = {}

var bytes_io: StreamPeerBuffer
var bc = RenCompiler.BCode
var dt = RenCompiler.DataTypes


func _init(globals: Dictionary = {}):
    self.globals = globals


func load_constant():
    var type = bytes_io.get_8()
    var value = null
    match type:
        dt.BOOL:
            value = bool(bytes_io.get_8())
        dt.INT8:
            value = bytes_io.get_8()
        dt.UINT8:
            value = bytes_io.get_u8()
        dt.INT16:
            value = bytes_io.get_16()
        dt.UINT16:
            value = bytes_io.get_u16()
        dt.INT32:
            value = bytes_io.get_32()
        dt.UINT32:
            value = bytes_io.get_u32()
        dt.INT64:
            value = bytes_io.get_64()
        dt.UINT64:
            value = bytes_io.get_u64()
        dt.FLOAT:
            value = bytes_io.get_double()
        dt.STRING:
            value = bytes_io.get_utf8_string()
        _:
            assert(false, 'Unknown datatype byte in constant at index: %s' % [bytes_io.get_position() - 1])
    
    assert(value != null, 'Value of constant is null for some reason...')
    data_stack.push_back(value)


func assign_name():
    var name = bytes_io.get_utf8_string()
    var value = data_stack.pop_back()
    self.globals[name] = value


func intepret(bytecode: PoolByteArray) -> void:
    bytes_io = StreamPeerBuffer.new()
    bytes_io.data_array = bytecode
    bytes_io.seek(0)
    
    while bytes_io.get_position() < bytes_io.get_size():
        var op_code = bytes_io.get_8()

        match op_code:
            bc.LOAD_CONST:
                load_constant()
            bc.ASSIGN_NAME:
                assign_name()
