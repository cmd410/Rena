extends RenAST
class_name RenUnOp


var token_map = {
    RenToken.PLUS: RenCompiler.BCode.POSITIVE,
    RenToken.MINUS: RenCompiler.BCode.NEGATIVE,
    RenToken.NOT: RenCompiler.BCode.NOT
}


func _init(token: RenToken, right: RenAST):
    self.token = token
    add_child(right)

func _to_string():
    return 'UnOp(%s)' % [self.token.token_type]



func visit(interp):
    match self.token.token_type:
        RenToken.PLUS:
            return +get_child(0).visit(interp)
        RenToken.MINUS:
            return -get_child(0).visit(interp)
        RenToken.NOT:
            return not get_child(0).visit(interp)
        _:
            assert(false, 'Invalid token for Unary operation')


func is_constant() -> bool:
    return get_child(0).is_constant()


func compiled(compiler, offset: int, jump_table: Dictionary = {}) -> PoolByteArray:
    # TODO check compilation to be correct
    # TODO calculate offset 
    var bytes_io = StreamPeerBuffer.new()
    if is_constant():
        var value = visit(null)
        compiler.put_constant(value, bytes_io)
    else:
        bytes_io.put_data(get_child(0).compiled(compiler, offset, jump_table))
        compiler.add_byte(token_map[self.token.token_type], bytes_io)
    return bytes_io.data_array