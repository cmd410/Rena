extends "AST.gd"

const RenToken = preload('../internal/Token.gd')

var value


func _init(token: RenToken):
    self.token = token
    self.value = token.value


func visit(_interp):
    return self.value
