extends Control


onready var tree = get_node("VBoxContainer/HBoxContainer/Tree") as Tree
onready var text_edit = get_node("VBoxContainer/HBoxContainer/TextEdit") as TextEdit
onready var log_container = get_node("VBoxContainer/HBoxContainer2/LOG") as TextEdit


func _ready():
    tree.hide_root = false


func printf(msg):
    log_container.text += str(msg)+'\n'


func cls():
    log_container.text = ''


func _on_Tokenize_pressed():
    var lexer: RenLexer = RenLexer.new(text_edit.text)
    cls()
    while not lexer.depleted:
        var result = lexer.get_next_token()
        if result is RenOK:
            printf(result.value)
        else:
            printf(result)
            break


func populate_tree(tree_item: TreeItem, node: Node):
    var new_item = tree.create_item(tree_item)
    new_item.set_text(0, str(node))
    for child in node.get_children():
        populate_tree(new_item, child)


func _on_BuildAST_pressed():
    var lexer = RenLexer.new(text_edit.text)
    var parser = RenParser.new(lexer)
    cls()
    
    var result = parser.script()
    if result is RenERR:
        printf(result)
        return
    
    var ast_root = result.value
    tree.clear()
    populate_tree(null, ast_root)
