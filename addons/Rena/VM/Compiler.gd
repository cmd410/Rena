extends "internal/Ref.gd"
class_name RenCompiler

# Mapping labels to index in bytecode
var jump_table: Dictionary = {}

# Store offsets that require jump indexes to labels
# that were not defined before jump statement
var pending_jumps: Dictionary = {}
var current_offset: int = 0


enum BCode {
    LOAD_NAME
    LOAD_CONST
    LOAD_ATTR
    LOAD_KEY
    
    ASSIGN_NAME
    ASSIGN_IF_NONE
    ASSIGN_IF_EXISTS
    ASSIGN_KEY
    ASSIGN_ATTR
    
    JUMP
    JUMP_IF_FALSE
    
    POP_TOP

    # BinOps
    ADD, SUB, MUL, DIV, FLOORDIV, POW
    MOD, LSHIFT, RSHIFT, XOR, BOR, BAND,
    EXEQ, NOEQ, LESS, GREATER, LEQ, GEQ, AND, OR
    IN

    # UnaryOps
    POSITIVE, NEGATIVE, NOT

    # Complex types
    BUILD_LIST
    BUILD_DICT

    # Statements
    SAY
    CALL_FUNC
    MENU
    RETURN
    CALL
}


enum DataTypes {
    BOOL
    UINT8
    INT8
    UINT16
    INT16
    UINT32
    INT32
    
    INT64
    UINT64
    
    FLOAT

    STRING

    ARRAY
}


func compile(tree, free_tree:bool = true) -> PoolByteArray:
    var bytes = tree.compiled(self, current_offset)
    current_offset += len(bytes)
    if free_tree:
        tree.queue_free()
    return post_process(bytes)


func compile_into_file(tree, filename: String, free_tree:bool = true) -> PoolByteArray:
    var bytes = compile(tree, free_tree)
    
    var out = File.new()
    out.open(filename, File.WRITE)
    out.store_buffer(bytes)
    out.close()

    return bytes


func post_process(bytecode: PoolByteArray) -> PoolByteArray:
    if not pending_jumps:
        return bytecode

    var bytes_io = StreamPeerBuffer.new()
    bytes_io.data_array = bytecode

    for idx in pending_jumps:
        var dest = pending_jumps[idx]

        var target_index = jump_table.get(dest)
        assert(target_index != null, "Could not find label: %s" % [dest])

        bytes_io.seek(idx)

        bytes_io.put_u32(target_index)
    
    return bytes_io.data_array


func put_constant(value, bytes_io: StreamPeerBuffer) -> void:
    bytes_io.put_8(BCode.LOAD_CONST)
    
    match typeof(value):
        
        TYPE_INT:
            var type = DataTypes.UINT64
            
            if value >= 0:
                if value <= pow(2, 8) - 1:
                    type = DataTypes.UINT8
                elif value <= pow(2, 16) - 1:
                    type = DataTypes.UINT16
                elif value <= pow(2, 32) - 1:
                    type = DataTypes.UINT32
            
            elif value < 0:
                if value >= -pow(2, 7):
                    type = DataTypes.INT8
                elif value >= -pow(2, 15):
                    type = DataTypes.INT16
                elif value >= -pow(2, 31):
                    type = DataTypes.INT32
                elif value >= -pow(2, 63):
                    type = DataTypes.INT63

            bytes_io.put_8(type)
                
            match type:
                DataTypes.UINT8:
                    bytes_io.put_u8(value)
                DataTypes.UINT16:
                    bytes_io.put_u16(value)
                DataTypes.UINT32:
                    bytes_io.put_u32(value)
                DataTypes.UINT64:
                    bytes_io.put_u64(value)
                DataTypes.INT8:
                    bytes_io.put_8(value)
                DataTypes.INT16:
                    bytes_io.put_16(value)
                DataTypes.INT32:
                    bytes_io.put_32(value)
                DataTypes.INT64:
                    bytes_io.put_64(value)
        
        TYPE_REAL:
            bytes_io.put_8(DataTypes.FLOAT)
            bytes_io.put_double(value)
        
        TYPE_STRING:
            bytes_io.put_8(DataTypes.STRING)
            bytes_io.put_utf8_string(value)

        TYPE_BOOL:
            bytes_io.put_8(DataTypes.BOOL)
            bytes_io.put_8(int(value))
        
        TYPE_ARRAY:
            bytes_io.put_8(DataTypes.ARRAY)
            bytes_io.put_var(value)
        _:
            assert(false, 'Value of unknown type: %s' % [self.value])
