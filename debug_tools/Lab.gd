extends Control


onready var tree = get_node("VBoxContainer/HBoxContainer4/HBoxContainer/VBoxContainer/Tree") as Tree
onready var text_edit = get_node("VBoxContainer/HBoxContainer4/HBoxContainer/TextEdit") as TextEdit
onready var log_container = get_node("VBoxContainer/HBoxContainer4/HBoxContainer2/VBoxContainer/LOG") as TextEdit

onready var cchar = get_node("VBoxContainer/HBoxContainer4/HBoxContainer2/VBoxContainer/HBoxContainer/CChar") as CheckBox
onready var ctoken = get_node("VBoxContainer/HBoxContainer4/HBoxContainer2/VBoxContainer/HBoxContainer/CToken") as CheckBox
onready var errors = get_node("VBoxContainer/HBoxContainer4/HBoxContainer2/VBoxContainer/HBoxContainer/Errors") as CheckBox


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


func populate_tree(tree_item: TreeItem, node: Node):
    var new_item = tree.create_item(tree_item)
    new_item.set_text(0, str(node))
    for child in node.get_children():
        populate_tree(new_item, child)


func _on_BuildAST_pressed():
    var lexer = RenLexer.new(text_edit.text)
    lexer.connect("new_token", self, '_on_token_parsed')
    var parser = RenParser.new(lexer)
    parser.connect("exception", self, '_on_error')
    cls()
    
    var result = parser.script()
    if result is RenERR:
        printf(result)
        return
    
    var ast_root = result.value
    tree.clear()
    populate_tree(null, ast_root)
