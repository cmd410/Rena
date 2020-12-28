tool
extends Control

signal action_verdict(is_allowed)

onready var tabs: TabContainer = get_node("VBox/HSplitContainer/TabContainer")
onready var label_list = get_node("VBox/HSplitContainer/ListsContainer/VBox/LabelsList")
onready var confirm_dialog = get_node("Confirmation")
onready var file_dialog = get_node("FileDialog")

var file_popup: PopupMenu
var edit_popup: PopupMenu

var label_map: Dictionary = {}

const file_menu_layout = [
    ['New', 'Open'],
    ['Save', 'Save as...'],
    ['Close']
   ]

const edit_menu_layout = [
    ['Undo', 'Redo'],
    ['Cut', 'Copy', 'Paste'],
    ['Select All'],
    ['Find', 'Repalce']
   ]


func get_current_editor() -> Node:
    return tabs.get_child(tabs.current_tab)


func _ready():
    confirm_dialog.get_ok().connect("pressed", self, '_on_action_confirmed')
    confirm_dialog.get_cancel().connect("pressed", self, '_on_action_canceled')
    confirm_dialog.get_close_button().connect("pressed", self, '_on_action_canceled')

    file_dialog.connect("file_selected", self, "_on_save_file")
    file_dialog.connect("file_selected", self, "_on_open_file")

    _setup_menus()

    tabs.set_popup(file_popup)


func _on_action_confirmed():
    emit_signal("action_verdict", true)


func _on_action_canceled():
    emit_signal("action_verdict", false)


func _set_menu_layout(menu: PopupMenu, layout: Array) -> void:
    menu.clear()
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
    edit_popup.connect("index_pressed", self, "_on_edit_idx_pressed")


func _on_edit_idx_pressed(idx: int):
    var editor: TextEdit = get_current_editor()
    match edit_popup.get_item_text(idx):
        'Undo':
            editor.undo()
        'Redo':
            editor.redo()
        'Cut':
            editor.cut()
        'Copy':
            editor.copy()
        'Paste':
            editor.paste()
        'Select All':
            editor.select_all()


func _on_file_idx_pressed(idx: int):
    match file_popup.get_item_text(idx):
        'New':
            create_new_editor('New Script')
            get_current_editor().text = ''
            get_current_editor().current_save_path = ''
        'Open':
            _open_file()
        'Save':
            if not get_current_editor().current_save_path:
                _save_as()
            else:
                _save(get_current_editor().current_save_path)
        'Save as...':
            _save_as()
        'Close':
            if get_current_editor().is_dirty:
                confirm_dialog.dialog_text = 'File was not saved! Are you sure you want to close it?'
                confirm_dialog.popup_centered()
                var accept = yield(self, 'action_verdict')
                if not accept:
                    return
            tabs.get_child(tabs.current_tab).queue_free()


func _save(filename):
    var file = File.new()
    file.open(filename, File.WRITE)
    file.store_string(get_current_editor().text)
    file.close()
    get_current_editor().is_dirty = false


func _save_as():
    file_dialog.clear_filters()
    file_dialog.add_filter("*.rena ; Rena script files")
    file_dialog.mode = file_dialog.MODE_SAVE_FILE
    file_dialog.popup_centered()


func _on_save_file(filename):
    if file_dialog.mode == file_dialog.MODE_SAVE_FILE:
        _save(filename)
        get_current_editor().current_save_path = filename
        tabs.set_tab_title(tabs.current_tab, filename.get_file())


func _open_file():
    file_dialog.clear_filters()
    file_dialog.add_filter("*.rena ; Rena script files")
    file_dialog.mode = file_dialog.MODE_OPEN_FILE
    file_dialog.popup_centered()

func create_new_editor(title):
    var new_editor: TextEdit = load('res://addons/Rena/UI/ScriptEditor.gd').new()
    
    new_editor.syntax_highlighting = true
    new_editor.highlight_all_occurrences = true
    new_editor.highlight_current_line = true
    new_editor.show_line_numbers = true
    new_editor.draw_tabs = true
    new_editor.minimap_draw = true

    new_editor.connect('text_changed', self, '_on_TextEdit_text_changed')
    
    tabs.add_child(new_editor)
    tabs.current_tab += 1
    tabs.set_tab_title(tabs.current_tab, title)

func _on_open_file(filename: String):
    if file_dialog.mode == file_dialog.MODE_OPEN_FILE:
        var file = File.new()
        file.open(filename, File.READ)

        create_new_editor(filename.get_file())

        get_current_editor().text = file.get_as_text()
        _on_TextEdit_text_changed()
        get_current_editor().is_dirty = false
        file.close()
        
        get_current_editor().current_save_path = filename


func _run_linting() -> void:
    # Find labels
    var label_regex = RegEx.new()
    label_regex.compile('\\blabel *([\\w_]+) *:')
    
    label_list.clear()
    label_map.clear()
    for result in label_regex.search_all(get_current_editor().text):
        var label = result.get_string(1)
        label_map[label] = result.get_end()
        label_list.add_item(label)


func _on_TextEdit_text_changed():
    get_current_editor().is_dirty = true
    _start_linting()

func _start_linting():
    $LintingTimer.stop()
    $LintingTimer.start()


func _on_LintingTimer_timeout():
    _run_linting()


func _on_LabelsList_item_selected(index):
    var label_pos = label_map[label_list.get_item_text(index)]
    
    var current_pos = 0
    var line_no = -1
    var column = 0
    for line in get_current_editor().text.split('\n'):
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

    get_current_editor().cursor_set_line(line_no)
    get_current_editor().cursor_set_column(column)


func _on_TabContainer_tab_changed(tab):
    _start_linting()
