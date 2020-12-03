extends RenRef
class_name RenInterp


var parser: RenParser = null

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
    
    print(ast.visit(self))
