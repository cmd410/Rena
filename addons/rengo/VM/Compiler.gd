extends RenRef
class_name RenCompiler

var file: StreamPeerBuffer = null

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
    self.file = StreamPeerBuffer.new()

    tree.compiled(self)

    var out = File.new()

    out.open('res://testcompile.rgc', File.WRITE)

    out.store_buffer(file.data_array)
    out.close()



func add_byte(byte: int):
    self.file.put_8(byte)


func put_utf8(s: String):
    file.put_utf8_string(s)


func put_constant(value):
    add_byte(BCode.LOAD_CONST)
    
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

            add_byte(type)
                
            match type:
                DataTypes.UINT8:
                    file.put_u8(value)
                DataTypes.UINT16:
                    file.put_u16(value)
                DataTypes.UINT32:
                    file.put_u32(value)
                DataTypes.UINT64:
                    file.put_u64(value)
                DataTypes.INT8:
                    file.put_8(value)
                DataTypes.INT16:
                    file.put_16(value)
                DataTypes.INT32:
                    file.put_32(value)
                DataTypes.INT64:
                    file.put_64(value)
        
        TYPE_REAL:
            add_byte(DataTypes.FLOAT)
            file.put_double(value)
        
        TYPE_STRING:
            add_byte(DataTypes.STRING)
            put_utf8(value)

        TYPE_BOOL:
            add_byte(DataTypes.BOOL)
            add_byte(int(value))
        TYPE_ARRAY:
            add_byte(DataTypes.ARRAY)
            file.put_var(value)
        _:
            assert(false, 'Value of unknown type: %s' % [self.value])
