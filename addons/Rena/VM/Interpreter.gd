extends "internal/Ref.gd"
class_name RenInterp


signal state_changed(interp)
signal say(who, what)
signal proceed()


var parser: RenParser = null

const RenERR = preload('internal/ERR.gd')

var defaults: Dictionary = {}
var defines: Dictionary = {}


func _init(parser: RenParser):
    self.parser = parser
    assert(self.parser != null)


func execute():
    var res = self.parser.script()
    if res is RenERR:
        return res
    var ast = res.value
    
    ast.visit(self)


func is_name_defined(name: String) -> bool:
    return defaults.has(name) or defines.has(name)


func get_name(name: String):
    if defaults.has(name):
        return defaults[name]
    elif defines.has(name):
        return defines[name]
    else:
        return null

func state_change():
    emit_signal('state_changed', self)

func say_statement(who, what):
    emit_signal('say', who, what)
    state_change()
