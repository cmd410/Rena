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

    OP
}


enum OPs {
    ADD, SUB
    MUL, DIV, FLOORDIV
    POSITIVE, NEGATIVE
    POW
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
