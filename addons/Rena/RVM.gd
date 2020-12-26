extends Node

const AST = preload('VM/ast/AST.gd')

signal started()
signal said(who, what, flush)
signal menu(prompt, options)
signal ended()
signal state_changed()

export(String, FILE) var source_filename

var default_globals: Dictionary = {}

var text: String = ''

var compiler: RenCompiler = RenCompiler.new()
var bci: RenBCI = RenBCI.new()


func _ready():
    _preset_defaults()
    _connect_signals()


func _preset_defaults() -> void:
    default_globals = {}


func _connect_signals() -> void:
    bci.connect('start', self, '_on_start')
    bci.connect('end', self, '_on_end')
    bci.connect('say', self, '_on_say')
    bci.connect('menu', self, '_on_menu')
    bci.connect('state_changed', self, '_on_state_changed')


func reset(reset_defaults: bool = false) -> void:
    # Clear compiler-interpreter state
    compiler = RenCompiler.new()
    bci = RenBCI.new()
    _connect_signals()
    if reset_defaults:
        clear_default_globals()


func clear_default_globals() -> void:
    default_globals.clear()


func set_default_global(name: String, value) -> void:
    default_globals[name] = value


func get_globals() -> Dictionary:
    return bci.globals


func get_runtime_variables() -> Dictionary:
    return bci.get_runtime_varialbes()


func set_text_from_file(filename: String) -> void:
    var file = File.new()
    file.open(filename, File.READ)
    text = file.get_as_text()
    file.close()


func set_text(text: String) -> void:
    self.text = text


func append_text(text: String) -> void:
    self.text += '\n%s' % [text]


func append_text_from_file(filename: String) -> void:
    var file = File.new()
    file.open(filename, File.READ)
    text += '\n%s' % [file.get_as_text()]
    file.close()


func clear_text() -> void:
    self.text = ''


func build_ast() -> AST:
    print_debug('Building AST...')
    return RenParser.new(RenLexer.new(self.text)).script().value


func compile() -> PoolByteArray:
    print_debug('Compiling bytecode...')
    assert(compiler != null, 'Compiler is not set!')
    return compiler.compile(build_ast())


func start() -> void:
    var bytecode = compile()

    print_debug('Starting interpreter...')
    assert(bci != null, 'Interpreter is not set!')
    
    if bci.globals != default_globals:
        bci.globals = default_globals.duplicate()

    var exec_state = bci.intepret(bytecode)

    if exec_state is GDScriptFunctionState and exec_state.is_valid():
        yield(exec_state, 'completed')


func next() -> void:
    bci.next()


func choose_option(option: String) -> bool:
    # Choose option from menu, returns false if option does not exist
    return bci.choose(option)


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
