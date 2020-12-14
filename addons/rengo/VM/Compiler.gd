extends RenRef
class_name RenCompiler

var file: File = null

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
}


enum DataTypes {
    UINT8
    UINT16
    UINT32
    
    INT64
    
    FLOAT
}


func compile(tree: RenAST, filename: String) -> PoolByteArray:
    self.file = File.new()
    self.file.open(filename, File.WRITE)

    var bytes = tree.compiled(self)
    
    self.file.close()

    return bytes

func add_byte(byte: int):
    self.file.store_8(byte)


func store_constant(value):
    add_byte(BCode.LOAD_CONST)
    
    match typeof(value):
        
        TYPE_INT:
            var type = DataTypes.INT64
            if value >= 0:
                if value <= pow(2, 8) - 1:
                    type = DataTypes.UINT8
                elif value <= pow(2, 16) - 1:
                    type = DataTypes.UINT16
                elif value <= pow(2, 32) - 1:
                    type = DataTypes.UINT32
                
            add_byte(type)
                
            match type:
                DataTypes.UINT8:
                    file.store_8(value)
                DataTypes.UINT16:
                    file.store_16(value)
                DataTypes.UINT32:
                    file.store_32(value)
                DataTypes.INT64:
                    file.store_64(value)
        
        TYPE_REAL:
            add_byte(DataTypes.FLOAT)
            file.store_float(value)
    
        _:
            assert(false, 'Value of unknown type: %s' % [self.value])
