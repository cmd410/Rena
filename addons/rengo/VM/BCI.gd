extends RenRef
class_name RenBCI
# ByteCode Interpreter

signal say(who, what)
signal menu(options)
signal choosen_option(option)
signal state_changed(interp)

var data_stack: Array = []
var globals: Dictionary = {}

var bytes_io: StreamPeerBuffer
var bc = RenCompiler.BCode
var dt = RenCompiler.DataTypes

var current_menu: Dictionary = {}


func _init(globals: Dictionary = {}):
    self.globals = globals


func choose(option: String):
    if option in current_menu:
        emit_signal("choosen_option", option)
    else:
        push_error('Option \"%s\" is not in current menu!' % [option])


func load_constant():
    var type = bytes_io.get_8()
    var value = null
    match type:
        dt.BOOL:
            value = bool(bytes_io.get_8())
        dt.INT8:
            value = bytes_io.get_8()
        dt.UINT8:
            value = bytes_io.get_u8()
        dt.INT16:
            value = bytes_io.get_16()
        dt.UINT16:
            value = bytes_io.get_u16()
        dt.INT32:
            value = bytes_io.get_32()
        dt.UINT32:
            value = bytes_io.get_u32()
        dt.INT64:
            value = bytes_io.get_64()
        dt.UINT64:
            value = bytes_io.get_u64()
        dt.FLOAT:
            value = bytes_io.get_double()
        dt.STRING:
            value = bytes_io.get_utf8_string()
        _:
            assert(false, 'Unknown datatype byte in constant at index: %s' % [bytes_io.get_position() - 1])
    
    assert(value != null, 'Value of constant is null for some reason...')
    data_stack.push_back(value)


func assign_name(overwrite: bool = true, must_exist: bool = false):
    var name = bytes_io.get_utf8_string()
    var value = data_stack.pop_back()
    
    var name_exists = self.globals.has(name)
    assert(not must_exist or name_exists, 'Name %s does not exist' % [name])
    
    if overwrite or not name_exists:
        self.globals[name] = value
        emit_signal('state_changed', self)


func build_dict():
    var n_elem = bytes_io.get_u32()
    var data = pop_n(n_elem * 2, false)
    var current_length = 0

    var d: Dictionary = {}
    while current_length < n_elem:
        var key = data.pop_back()
        var value = data.pop_back()
        d[key] = value
        current_length += 1
    
    data_stack.push_back(d)


func make_menu():
    var count = bytes_io.get_u32()
    var data = pop_n(count * 2, false)
    for i in range(count):
        var option = data.pop_back()
        var idx = data.pop_back()

        self.current_menu[option] = idx


func pop_n(n: int, reverse: bool = true) -> Array:
    var arr = Array()
    for i in range(n):
        arr.push_back(data_stack.pop_back())
    if reverse:
        arr.invert()
    return arr


func bin_op(op: String):
    var right = data_stack.pop_back()
    var left = data_stack.pop_back()
    var result = null
    match op:
        '+':
            result = left + right
        '-':
            result = left - right
        '*':
            result = left * right
        '/':
            result = left / right
        '//':
            result = floor(left / right)
        '**':
            result = pow(left, right)
        '%':
            result = left % right
        '<<':
            result = left << right
        '>>':
            result = left >> right
        '^':
            result = left ^ right
        '|':
            result = left | right
        '&':
            result = left & right
        '==':
            result = left == right
        '!=':
            result = left != right
        '<':
            result = left < right
        '>':
            result = left > right
        '<=':
            result = left <= right
        '>=':
            result = left >= right
        'and':
            result = left and right
        'or':
            result = left or right
    assert(result != null, 'Result of binary operation is null!')
    data_stack.push_back(result)
        

func intepret(bytecode: PoolByteArray) -> void:
    bytes_io = StreamPeerBuffer.new()
    bytes_io.data_array = bytecode
    bytes_io.seek(0)
    
    while bytes_io.get_position() < bytes_io.get_size():
        var op_code = bytes_io.get_u8()

        match op_code:
            bc.LOAD_CONST:
                load_constant()
            bc.ASSIGN_NAME:
                assign_name()
            bc.ASSIGN_IF_NONE:
                assign_name(false)
            bc.ASSIGN_IF_EXISTS:
                assign_name(true, true)
            bc.LOAD_NAME:
                var name = bytes_io.get_utf8_string()
                assert(globals.has(name), 'Name "%s" is not defined' % [name])
                data_stack.push_back(globals[name])
            
            bc.JUMP:
                var dest = bytes_io.get_u32()
                bytes_io.seek(dest)
            bc.JUMP_IF_FALSE:
                var dest = bytes_io.get_u32()
                var value = data_stack.pop_back()
                if not value:
                    bytes_io.seek(dest)
            
            bc.BUILD_LIST:
                var count = bytes_io.get_u32()
                var list = pop_n(count)
                data_stack.push_back(list)
            
            bc.BUILD_DICT:
                build_dict()
            
            bc.MENU:
                make_menu()
                emit_signal("menu", current_menu.keys())
                var op = yield(self, "choosen_option")
                bytes_io.seek(current_menu[op])

            bc.POSITIVE:
                data_stack.push_back(+data_stack.pop_back())
            bc.NEGATIVE:
                data_stack.push_back(-data_stack.pop_back())
            bc.NOT:
                data_stack.push_back(not data_stack.pop_back())

            bc.ADD:
                bin_op('+')
            bc.SUB:
                bin_op('-')
            bc.MUL:
                bin_op('*')
            bc.DIV:
                bin_op('/')
            bc.FLOORDIV:
                bin_op('//')
            bc.POW:
                bin_op('**')
            bc.MOD:
                bin_op('%')
            bc.LSHIFT:
                bin_op('<<')
            bc.RSHIFT:
                bin_op('>>')
            bc.XOR:
                bin_op('^')
            bc.BOR:
                bin_op('|')
            bc.BAND:
                bin_op('&')
            bc.EXEQ:
                bin_op('==')
            bc.NOEQ:
                bin_op('!=')
            bc.LESS:
                bin_op('<')
            bc.GREATER:
                bin_op('>')
            bc.LEQ:
                bin_op('<=')
            bc.GEQ:
                bin_op('>=')
            bc.AND:
                bin_op('and')
            bc.OR:
                bin_op('or')
            _:
                assert(false, 'Unrecognized instruction byte: %s' % [op_code])
