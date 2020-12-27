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

var default_globals: Dictionary = {}

var text: String = ''

var compiler: RenCompiler = null
var bci: RenBCI = null

var globals setget set_globals, get_globals


func set_globals(value):
    bci.globals = value


func get_globals():
    return bci.globals


func _ready():
    if source_filename:
        set_text_from_file(source_filename)
    _preset_defaults()
    reset()


func _preset_defaults() -> void:
    # Can be overriden by subclasses to initialise globals on _ready
    default_globals = {}


func _connect_signals() -> void:
    bci.connect('start', self, '_on_start')
    bci.connect('end', self, '_on_end')
    bci.connect('say', self, '_on_say')
    bci.connect('menu', self, '_on_menu')
    bci.connect('state_changed', self, '_on_state_changed')


func reset() -> void:
    # Clear compiler-interpreter state
    compiler = RenCompiler.new()
    bci = RenBCI.new(default_globals)
    _connect_signals()


func set_default_global(name: String, value) -> void:
    default_globals[name] = value


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
