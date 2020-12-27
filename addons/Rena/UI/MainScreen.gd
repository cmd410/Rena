tool
extends Control

signal action_verdict(is_allowed)

onready var script_editor = get_node("VBox/HSplitContainer/TextEdit")
onready var label_list = get_node("VBox/HSplitContainer/ListsContainer/VBox/LabelsList")
onready var confirm_dialog = get_node("Confirmation")
onready var file_dialog = get_node("FileDialog")

var file_popup: PopupMenu
var edit_popup: PopupMenu

# True if script was changed without saving
var script_is_dirty: bool = false
var current_save_path: String = ''

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
    confirm_dialog.get_ok().connect("pressed", self, '_on_action_confirmed')
    confirm_dialog.get_cancel().connect("pressed", self, '_on_action_canceled')
    confirm_dialog.get_close_button().connect("pressed", self, '_on_action_canceled')

    file_dialog.connect("file_selected", self, "_on_save_file")
    file_dialog.connect("file_selected", self, "_on_open_file")

    _setup_menus()


func _on_action_confirmed():
    emit_signal("action_verdict", true)


func _on_action_canceled():
    emit_signal("action_verdict", false)


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
    match file_popup.get_item_text(idx):
        'New':
            if script_is_dirty:
                confirm_dialog.dialog_text = """Current script was not saved! Are you sure you want to create a new one?"""
                confirm_dialog.popup_centered()
                var accept = yield(self, "action_verdict")
                if accept:
                    script_editor.text = ''
                    current_save_path = ''
                    script_is_dirty = false
            else:
                script_editor.text = ''
                current_save_path = ''
        'Open':
            if script_is_dirty:
                confirm_dialog.dialog_text = """Current script was not saved! Are you sure you want to open other one?"""
                confirm_dialog.popup_centered()
                var accept = yield(self, "action_verdict")
                if accept:
                    _open_file()
            else:
                _open_file()
        'Save':
            if not current_save_path:
                _save_as()
            else:
                _save(current_save_path)
        'Save as...':
            _save_as()


func _save(filename):
    var file = File.new()
    file.open(filename, File.WRITE)
    file.store_string(script_editor.text)
    file.close()
    script_is_dirty = false


func _save_as():
    file_dialog.clear_filters()
    file_dialog.add_filter("*.rena ; Rena script files")
    file_dialog.mode = file_dialog.MODE_SAVE_FILE
    file_dialog.popup_centered()


func _on_save_file(filename):
    if file_dialog.mode == file_dialog.MODE_SAVE_FILE:
        _save(filename)
        current_save_path = filename


func _open_file():
    file_dialog.clear_filters()
    file_dialog.add_filter("*.rena ; Rena script files")
    file_dialog.mode = file_dialog.MODE_OPEN_FILE
    file_dialog.popup_centered()


func _on_open_file(filename):
    if file_dialog.mode == file_dialog.MODE_OPEN_FILE:
        var file = File.new()
        file.open(filename, File.READ)
        script_editor.text = file.get_as_text()
        _on_TextEdit_text_changed()
        script_is_dirty = false
        file.close()
        
        current_save_path = filename


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


func _on_TextEdit_text_changed():
    script_is_dirty = true
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
