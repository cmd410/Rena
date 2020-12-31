extends Node

const AST = preload('VM/ast/AST.gd')

signal started()
signal said(who, what, flush)
signal menu(prompt, options)
signal ended()
signal state_changed()

const RenCompiler = preload('VM/Compiler.gd')
const RenBCI = preload('VM/BCI.gd')
const RenLexer = preload('VM/Lexer.gd')
const RenParser = preload('VM/Parser.gd')

export(String, FILE) var source_filename

var text: String = ''
var path: String = ''

var compiler: RenCompiler = null
var bci: RenBCI = null

var globals: Dictionary = {}


func _ready():
    if source_filename:
        set_text_from_file(source_filename)
    reset()


func _connect_signals() -> void:
    bci.connect('start', self, '_on_start')
    bci.connect('end', self, '_on_end')
    bci.connect('say', self, '_on_say')
    bci.connect('menu', self, '_on_menu')
    bci.connect('state_changed', self, '_on_state_changed')


func reset() -> void:
    # Clear compiler-interpreter state
    compiler = RenCompiler.new()
    bci = RenBCI.new(globals)
    _connect_signals()


func get_runtime_variables() -> Dictionary:
    return bci.get_runtime_varialbes()


func set_text_from_file(filename: String) -> void:
    path = filename
    var file = File.new()
    file.open(filename, File.READ)
    text = file.get_as_text()
    file.close()


func set_text(text: String) -> void:
    path = ''
    self.text = text


func append_text(text: String) -> void:
    path = ''
    self.text += '\n%s' % [text]


func append_text_from_file(filename: String) -> void:
    path = ''
    var file = File.new()
    file.open(filename, File.READ)
    text += '\n%s' % [file.get_as_text()]
    file.close()
    reset()


func clear_text() -> void:
    self.text = ''


func build_ast() -> AST:
    print_debug('Building AST...')
    return RenParser.new(RenLexer.new(self.text)).script().value


func compile(output_file: String = '') -> PoolByteArray:
    print_debug('Compiling bytecode...')
    assert(compiler != null, 'Compiler is not set!')
    if output_file:
        return compiler.compile_into_file(build_ast(), output_file)
    else:
        return compiler.compile(build_ast())


func start() -> void:
    if compiler == null or bci == null:
        reset()

    var bytecode = compile()

    print_debug('Starting interpreter...')
    assert(bci != null, 'Interpreter is not set!')
    
    bci.globals = globals

    var exec_state = bci.start(bytecode)

    if exec_state is GDScriptFunctionState and exec_state.is_valid():
        yield(exec_state, 'completed')


func next() -> void:
    bci.next()


func choose_option(option: String) -> bool:
    # Choose option from menu, returns false if option does not exist
    return bci.choose(option)


func get_save_data() -> Dictionary:
    var data = bci.get_save_data()

    data['path'] = path
    if not path:
        data['text'] = text

    return data


func start_from_save(data: Dictionary):
    var filename = data.get('path', '')
    if not filename:
        set_text(data.get('text', ''))
    else:
        set_text_from_file(filename)
    
    globals = data.get('globals', globals)
    
    reset()

    var bytecode = compile()

    return bci.start_from_save(bytecode, data)


func _on_say(who, what, flush: bool) -> void:
    emit_signal('said', who, what, flush)


func _on_menu(prompt: String, options: Array) -> void:
    emit_signal('menu', prompt, options)


func _on_state_changed(interp: RenBCI) -> void:
    emit_signal('state_changed')


func _on_start() -> void:
    emit_signal('started')


func _on_end() -> void:
    emit_signal('ended')
