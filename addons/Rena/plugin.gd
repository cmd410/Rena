tool
extends EditorPlugin


const MainScreen = preload('UI/MainScreen.tscn')


var main_screen_instance


func _enter_tree() -> void:
    add_custom_type(
        'RenaVM', 'Node',
        load('res://addons/Rena/RVM.gd'),
        load('res://addons/Rena/rena_icon.svg')
    )

    _setup_ui()


func _exit_tree() -> void:
    _teardown_ui()
    remove_custom_type('RenaVM')


func _setup_ui() -> void:
    main_screen_instance = MainScreen.instance()
    var ed_interface = get_editor_interface()
    var ed_viewport = ed_interface.get_editor_viewport()

    ed_viewport.add_child(main_screen_instance)

    make_visible(false)


func _teardown_ui() -> void:
    pass


func has_main_screen() -> bool:
    return true


func make_visible(visible):
    if main_screen_instance:
        main_screen_instance.visible = visible


func get_plugin_name():
    return 'Rena'

func get_plugin_icon():
    return load('res://addons/Rena/rena_icon.svg')

