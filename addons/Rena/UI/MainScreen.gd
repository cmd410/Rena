tool
extends Control

onready var script_editor = get_node("VBox/HSplitContainer/TextEdit")
onready var label_list = get_node("VBox/HSplitContainer/ListsContainer/VBox/LabelsList")

var file_popup: PopupMenu
var edit_popup: PopupMenu

# True if script was changed without saving
var script_is_dirty: bool = false

var label_map: Dictionary = {}

const file_menu_layout = [
    ['New', 'Open'],
    ['Save', 'Save as...']
   ]

const edit_menu_layout = [
    ['Undo', 'Redo'],
    ['Cut', 'Copy', 'Paste'],
    ['Select All'],
    ['Find', 'Repalce']
   ]

func _ready():
    _setup_menus()


func _set_menu_layout(menu: PopupMenu, layout: Array) -> void:
    var i = 0
    for section in layout:
        i += 1
        for item in section:
            menu.add_item(item)
        if i != len(layout):
            menu.add_separator()


func _setup_menus() -> void:
    var file_menu_button = get_node("VBox/MenuContainer/FileButton")
    file_popup = file_menu_button.get_popup()
    _set_menu_layout(file_popup, file_menu_layout)
    file_popup.connect("index_pressed", self, "_on_file_idx_pressed")
    
    var edit_menu_button = get_node("VBox/MenuContainer/EditButton")
    edit_popup = edit_menu_button.get_popup()
    _set_menu_layout(edit_popup, edit_menu_layout)


func _on_file_idx_pressed(idx: int):
    var button_text = file_popup.get_item_text(idx)


func _run_linting() -> void:
    # Find labels
    var label_regex = RegEx.new()
    label_regex.compile('\\blabel *([\\w_]+) *:')
    
    label_list.clear()
    label_map.clear()
    for result in label_regex.search_all(script_editor.text):
        var label = result.get_string(1)
        label_map[label] = result.get_end()
        label_list.add_item(label)
    print(label_map)


func _on_TextEdit_text_changed():
    $LintingTimer.stop()
    $LintingTimer.start()


func _on_LintingTimer_timeout():
    _run_linting()


func _on_LabelsList_item_selected(index):
    var label_pos = label_map[label_list.get_item_text(index)]
    
    var current_pos = 0
    var line_no = -1
    var column = 0
    for line in script_editor.text.split('\n'):
        line_no += 1
        current_pos += len(line)
        if current_pos >= label_pos:
            if current_pos > label_pos:
                column = len(line) - (current_pos - label_pos)
            else:
                if line_no != 0:
                    column = floor(current_pos / line_no)
                else:
                    column = current_pos
            break
    script_editor.cursor_set_line(line_no)
    script_editor.cursor_set_column(column)
