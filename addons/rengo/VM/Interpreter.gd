extends RenRef
class_name RenInterp

var parser: RenParser = null

func _init(parser: RenParser):
    self.parser = parser
    assert(self.parser != null)


