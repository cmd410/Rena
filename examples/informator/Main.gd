extends Control


const RVM = preload('res://addons/Rena/RVM.gd')

var current_save = null
onready var vm: RVM = get_node('RenaVM')

func _ready():
    init_dialog('res://examples/informator/story/script.rena')


func init_dialog(source: String):
    vm.set_text_from_file(source)
    vm.start()


func _on_SaveButton_pressed():
    current_save = vm.get_save_data()


func _on_LoadButton_pressed():
    if current_save != null:
        vm.start_from_save(current_save)
