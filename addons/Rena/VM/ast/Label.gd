extends "AST.gd"

const RenToken = preload('../internal/Token.gd')


func _init(token: RenToken):
    self.token = token
    self.id = token.value


func _to_string():
    return 'Label(%s)' % [self.id]


func visit(interp):
    var compound = get_child(0)

    var result = compound.visit(interp)
    
    if result is GDScriptFunctionState and result.is_valid():
        yield(result, 'completed')


func compiled(compiler, offset: int) -> PoolByteArray:
    compiler.jump_table[self.id] = offset
    return get_child(0).compiled(compiler, offset)
