extends RenAST
class_name RenReturn


func _to_string():
    return 'Return'


func compiled(compiler, _offset: int) -> PoolByteArray:
    return PoolByteArray([compiler.BCode.RETURN])
