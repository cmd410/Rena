extends Control


onready var tree: Tree = get_node("VBox/HBox2/HBox/HBox/VBox/Tree")
onready var text_edit: TextEdit = get_node("VBox/HBox2/HBox/HBox/TextEdit")
onready var log_container: TextEdit = get_node("VBox/HBox2/HBox/HBox2/VBox2/LOG")
onready var state_tree: Tree = get_node("VBox/HBox2/HBox/HBox2/VBox3/StateTree")

onready var cchar: CheckBox = get_node("VBox/HBox2/HBox/HBox2/VBox2/HBox/CChar")
onready var ctoken: CheckBox = get_node("VBox/HBox2/HBox/HBox2/VBox2/HBox/CToken")
onready var errors: CheckBox = get_node("VBox/HBox2/HBox/HBox2/VBox2/HBox/Errors")

var interp = null


func _ready():
    tree.hide_root = false


func printf(msg):
    log_container.text += str(msg)+'\n'


func cls():
    log_container.text = ''


func _on_Tokenize_pressed():
    var lexer: RenLexer = RenLexer.new(text_edit.text)
    if ctoken.pressed:
        lexer.connect("new_token", self, '_on_token_parsed')
    if errors.pressed:
        lexer.connect("exception", self, '_on_error')
    if cchar.pressed:
        lexer.connect("advanced", self, "_on_token_parsed")
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
    

func state_update(interp):
    state_tree.clear()
    var root = state_tree.create_item(null)
    root.set_text(0, 'Interpreter')
    
    var defines = state_tree.create_item(root)
    defines.set_text(0, 'defines')
    for key in interp.defines:
        var k = state_tree.create_item(defines)
        k.set_text(0, key)
        var value = state_tree.create_item(k)
        value.set_text(0, str(interp.defines[key]))
    
    var defaults = state_tree.create_item(root)
    defaults.set_text(0, 'defaults')
    for key in interp.defaults:
        var k = state_tree.create_item(defaults)
        k.set_text(0, key)
        var value = state_tree.create_item(k)
        value.set_text(0, str(interp.defaults[key]))


func _on_Proceed_pressed():
    if interp != null:
        interp.emit_signal('proceed')


func _on_Compile_pressed():
    var lexer = RenLexer.new(self.text_edit.text)
    var parser = RenParser.new(lexer)
    
    var compiler = RenCompiler.new()
    compiler.compile(parser.script().value, 'res://testcompile.rgc')
