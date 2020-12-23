tool
extends EditorPlugin


func _enter_tree():
    add_custom_type(
        'RenaVM', 'Node',
        load('res://addons/Rena/RVM.gd'),
        load('res://addons/Rena/icon.png')
    )


func _exit_tree():
    remove_custom_type('RenaVM')
