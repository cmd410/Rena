extends Control


onready var tree: Tree = get_node("VBox/HBox2/HBox/HBox/VBox/Tree")
onready var text_edit: TextEdit = get_node("VBox/HBox2/HBox/HBox/TextEdit")
onready var log_container: TextEdit = get_node("VBox/HBox2/HBox/HBox2/VBox2/LOG")
onready var state_tree: Tree = get_node("VBox/HBox2/HBox/HBox2/VBox3/StateTree")

onready var cchar: CheckBox = get_node("VBox/HBox2/HBox/HBox2/VBox2/HBox/CChar")
onready var ctoken: CheckBox = get_node("VBox/HBox2/HBox/HBox2/VBox2/HBox/CToken")
onready var errors: CheckBox = get_node("VBox/HBox2/HBox/HBox2/VBox2/HBox/Errors")
onready var option_box: HBoxContainer = get_node("VBox/HBox2/HBox/HBox2/VBox2/OptionsBox")

var interp = null

const RenAST = preload('res://addons/Rena/VM/ast/AST.gd')
const RenLexer = preload('res://addons/Rena/VM/Lexer.gd')
const RenParser = preload('res://addons/Rena/VM/Parser.gd')
const RenInterp = preload('res://addons/Rena/VM/Interpreter.gd')
const RenCompiler = preload('res://addons/Rena/VM/Compiler.gd')
const RenBCI = preload('res://addons/Rena/VM/BCI.gd')

const RenOK = preload('res://addons/Rena/VM/internal/OK.gd')
const RenERR = preload('res://addons/Rena/VM/internal/ERR.gd')

# TODO cleanup this script


func _ready():
    tree.hide_root = false


func printf(msg):
    log_container.text += str(msg)+'\n'


func cls():
    log_container.text = ''


func _on_Tokenize_pressed():
    var lexer: RenLexer = RenLexer.new(text_edit.text)

    var err = 0
    if ctoken.pressed:
        err |= lexer.connect("new_token", self, '_on_token_parsed')
    if errors.pressed:
        err |= lexer.connect("exception", self, '_on_error')
    if cchar.pressed:
        err |= lexer.connect("advanced", self, "_on_token_parsed")
    
    assert(not err, 'Could not connect all signals of lexer')

    cls()
    while not lexer.depleted:
        var result = lexer.get_next_token()
        if result is RenOK:
            printf(result.value)
        else:
            break


func _on_token_parsed(token):
    printf(token)


func _on_error(err):
    printf(err)


func _on_say_statement(who, what):
    printf('%s: %s' % [who, what])


func populate_tree(tree_item: TreeItem, node: Node):
    var new_item = tree.create_item(tree_item)
    new_item.set_text(0, str(node))
    for child in node.get_children():
        populate_tree(new_item, child)


func _on_BuildAST_pressed():
    var lexer = RenLexer.new(text_edit.text)
    
    if ctoken.pressed:
        lexer.connect("new_token", self, '_on_token_parsed')
    if errors.pressed:
        lexer.connect("exception", self, '_on_error')
    if cchar.pressed:
        lexer.connect("advanced", self, "_on_token_parsed")
    
    var parser = RenParser.new(lexer)
    cls()
    
    var result = parser.script()
    if result is RenERR:
        printf(result)
        return
    
    var ast_root = result.value
    build_ast(ast_root)


func build_ast(node: RenAST):
    tree.clear()
    populate_tree(null, node)


func _on_Execute_pressed():
    var lexer = RenLexer.new(text_edit.text)
    var parser = RenParser.new(lexer)
    interp = RenInterp.new(parser)

    interp.connect('say', self, '_on_say_statement')
    interp.connect('state_changed', self, 'state_update')
    
    parser.connect("ast_built", self, 'build_ast')
    
    if ctoken.pressed:
        lexer.connect("new_token", self, '_on_token_parsed')
    if errors.pressed:
        lexer.connect("exception", self, '_on_error')
    if cchar.pressed:
        lexer.connect("advanced", self, "_on_token_parsed")
    
    interp.execute()
    

func state_update(ast_interpeter):
    state_tree.clear()
    var root = state_tree.create_item(null)
    root.set_text(0, 'Interpreter')
    
    var defines = state_tree.create_item(root)
    defines.set_text(0, 'defines')
    for key in ast_interpeter.defines:
        var k = state_tree.create_item(defines)
        k.set_text(0, key)
        var value = state_tree.create_item(k)
        value.set_text(0, str(ast_interpeter.defines[key]))
    
    var defaults = state_tree.create_item(root)
    defaults.set_text(0, 'defaults')
    for key in ast_interpeter.defaults:
        var k = state_tree.create_item(defaults)
        k.set_text(0, key)
        var value = state_tree.create_item(k)
        value.set_text(0, str(ast_interpeter.defaults[key]))


func _on_Proceed_pressed():
    if interp != null:
        if interp is RenInterp:
            interp.emit_signal('proceed')
        elif interp is RenBCI:
            interp.emit_signal('next')


func _on_Compile_pressed():
    var lexer = RenLexer.new(self.text_edit.text)
    var parser = RenParser.new(lexer)
    parser.connect("ast_built", self, 'build_ast')
    var compiler = RenCompiler.new()
    compiler.compile_into_file(parser.script().value, 'res://testcompile.rc')


func _on_option_chosen(op: String):
    for i in option_box.get_children():
        i.queue_free()
    interp.choose(op)


func _on_menu(prompt: String, ops: Array):
    printf("Menu \"%s\": %s" % [prompt, ops])
    for o in ops:
        var button = (load("res://debug_tools/Option_button.gd") as GDScript).new()
        button.connect("option_chosen", self, "_on_option_chosen")
        button.text = o
        option_box.add_child(button)


func _on_Run_Bytecode_pressed():
    var lexer = RenLexer.new(text_edit.text)
    var parser = RenParser.new(lexer)
    parser.connect("ast_built", self, 'build_ast')
    var ast = parser.script().value
    var compiler = RenCompiler.new()
    var bytecode = compiler.compile(ast)
    
    var bci = RenBCI.new()
    interp = bci
    bci.connect("menu", self, "_on_menu")
    bci.connect("say", self, "_on_bci_say")
    bci.connect('state_changed', self, '_bci_state_update')
    bci.intepret(bytecode)


func _on_bci_say(who, what, _flush):
    printf('%s : \"%s\"' % [who, what])


func _bci_state_update(bci):
    state_tree.clear()
    var root = state_tree.create_item(null)
    root.set_text(0, 'Interpreter')
    
    var globals = state_tree.create_item(root)
    globals.set_text(0, 'Globals')
    
    for key in bci.globals:
        var k = state_tree.create_item(globals)
        k.set_text(0, key)
        var value = state_tree.create_item(k)
        value.set_text(0, str(bci.globals[key]))
