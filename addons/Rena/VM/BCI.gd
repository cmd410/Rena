extends RenRef
class_name RenBCI
# ByteCode Interpreter

signal say(who, what, flush)
signal menu(prompt, options)
signal choosen_option(option)
signal state_changed(interp)
signal next()
signal start()
signal end()

var data_stack: Array = []
var jump_stack: Array = []
var globals: Dictionary = {}

var bytes_io: StreamPeerBuffer
var bc = RenCompiler.BCode
var dt = RenCompiler.DataTypes

var current_menu: Dictionary = {}
var current_menu_prompt: String = ''


func _init(globals: Dictionary = {}):
    self.globals = globals
    self.globals['null'] = null


func choose(option: String):
    if option in current_menu:
        emit_signal("choosen_option", option)
    else:
        push_error('Option \"%s\" is not in current menu!' % [option])


func next():
    emit_signal('next')


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
    current_menu_prompt = bytes_io.get_utf8_string()
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
        

func intepret(bytecode: PoolByteArray) -> void:
    bytes_io = StreamPeerBuffer.new()
    bytes_io.data_array = bytecode
    bytes_io.seek(0)

    emit_signal('start')
    while bytes_io.get_position() < bytes_io.get_size():
        var op_code = bytes_io.get_u8()
        #print('%s - %s' % [bytes_io.get_position(), op_code])
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
            bc.CALL:
                var dest = bytes_io.get_u32()
                jump_stack.push_back(bytes_io.get_position())
                bytes_io.seek(dest)
            
            bc.LOAD_ATTR:
                var namespace = data_stack.pop_back()
                var name = bytes_io.get_utf8_string()
                assert(namespace.has(name), '%s has no attribute %s' % [namespace, name])
                data_stack.push_back(namespace.get(name))
            
            bc.LOAD_KEY:
                var name = data_stack.pop_back()
                var namespace = data_stack.pop_back()
                assert(namespace.has(name), '%s has no attribute %s' % [namespace, name])
                data_stack.push_back(namespace[name])

            bc.BUILD_LIST:
                var count = bytes_io.get_u32()
                var list = pop_n(count)
                data_stack.push_back(list)
            
            bc.BUILD_DICT:
                build_dict()
            
            bc.MENU:
                make_menu()
                emit_signal("menu", self.current_menu_prompt , self.current_menu.keys())
                var op = yield(self, "choosen_option")
                bytes_io.seek(self.current_menu[op])
                self.current_menu.clear()
                self.current_menu_prompt = ''
            
            bc.SAY:
                var count = bytes_io.get_u32()
                if count == 1:
                    var what = data_stack.pop_back()
                    emit_signal('say', '', what, true)
                    yield(self, 'next')
                else:
                    var data = pop_n(count, false)
                    var who = data.pop_back()
                    while not data.empty():
                        var what = data.pop_back()
                        var flush = data.empty()
                        emit_signal('say', who, what, flush)
                        yield(self, 'next')
            
            bc.CALL_FUNC:
                var function = data_stack.pop_back() as FuncRef
                assert(function != null, 'Attempt to call non-callable object!')
                var args_count = bytes_io.get_u32()
                data_stack.push_back((function.call_funcv(pop_n(args_count))))
            
            bc.POSITIVE:
                data_stack.push_back(+data_stack.pop_back())
            bc.NEGATIVE:
                data_stack.push_back(-data_stack.pop_back())
            bc.NOT:
                data_stack.push_back(not data_stack.pop_back())
            
            bc.RETURN:
                if jump_stack.empty():
                    break
                else:
                    var dest = jump_stack.pop_back()
                    bytes_io.seek(dest)
            
            bc.ADD:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left + right)
            bc.SUB:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left - right)
            bc.MUL:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left * right)
            bc.DIV:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left / right)
            bc.FLOORDIV:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(floor(left / right))
            bc.POW:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(pow(left, right))
            bc.MOD:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left % right)
            bc.LSHIFT:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left << right)
            bc.RSHIFT:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left >> right)
            bc.XOR:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left ^ right)
            bc.BOR:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left | right)
            bc.BAND:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left & right)
            bc.EXEQ:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left == right)
            bc.NOEQ:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left != right)
            bc.LESS:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left < right)
            bc.GREATER:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left > right)
            bc.LEQ:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left <= right)
            bc.GEQ:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left >= right)
            bc.AND:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left and right)
            bc.OR:
                var right = data_stack.pop_back()
                var left = data_stack.pop_back()
                data_stack.push_back(left or right)
            
            bc.POP_TOP:
                data_stack.pop_back()

            _:
                assert(false, 'Unrecognized instruction byte: %s' % [op_code])
    
    emit_signal('end')