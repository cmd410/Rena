extends RenRef
class_name RenCompiler


var jump_table: Dictionary = {}


enum BCode {
    LOAD_NAME
    LOAD_CONST
    
    ASSIGN_NAME
    ASSIGN_IF_NONE
    ASSIGN_IF_EXISTS
    
    JUMP
    JUMP_IF_FALSE
    
    POP_TOP

    # BinOps
    ADD, SUB, MUL, DIV, FLOORDIV, POW
    MOD, POW, LSHIFT, RSHIFT, XOR, BOR, BAND,
    EXEQ, NOEQ, LESS, GREATER, LEQ, GEQ, AND, OR

    # UnaryOps
    POSITIVE, NEGATIVE, NOT

    # Complex types
    BUILD_LIST
    BUILD_DICT

    # Statements
    SAY
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


func compile(tree: RenAST, filename: String):
    
    var bytes = tree.compiled(self, 0, self.jump_table)

    var out = File.new()

    out.open('res://testcompile.rgc', File.WRITE)

    out.store_buffer(bytes)
    out.close()


func put_constant(value, bytes_io: StreamPeerBuffer):
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
