extends Control


const RVM = preload('res://addons/Rena/RVM.gd')


func _ready():
    init_dialog('res://examples/informator/story/script.rena')


func init_dialog(source: String):
    var vm = $RenaVM as RVM
    vm.set_text_from_file(source)
    vm.start()
