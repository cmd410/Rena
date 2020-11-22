tool
extends EditorPlugin


const SINGLETONS = {
    'RenConsts': 'res://addons/rengo/RenVM/RenConsts.gd'
   }


func _enter_tree():
    # Register autoload singletons
    for key in SINGLETONS:
        add_autoload_singleton(key, SINGLETONS[key])

func _exit_tree():
    # Cleanup autoload singletons
    for key in SINGLETONS:
        remove_autoload_singleton(key)
