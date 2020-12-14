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
