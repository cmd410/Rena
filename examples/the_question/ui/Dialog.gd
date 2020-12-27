extends Control


const MenuOptionButton = preload("MenuOptionButton.tscn")
const RenaVM = preload("res://addons/Rena/RVM.gd")

onready var name_label: RichTextLabel = get_node("VBox/SpeechRect/HBox/VBox/NameLabel")
onready var speech_label: RichTextLabel = get_node("VBox/SpeechRect/HBox/VBox/SpeechLabel")
onready var menu_container: VBoxContainer = get_node("CenterContainer/Menu")


var current_name = ''
var current_color = Color('#ffffff')

export(NodePath) var VirtualMachine: NodePath
var VM


func _ready():
    set_process(false)
    if VirtualMachine:
        set_vm(get_node(VirtualMachine))


func set_vm(vm):
    VM = vm
    VM.connect("started", self, "_on_started")
    VM.connect("ended", self, "_on_ended")
    VM.connect("said", self, "_on_said")
    VM.connect("menu", self, "_on_menu")
    VM.start()


func _process(delta):
    if Input.is_action_just_pressed("ui_accept"):
        next()


func set_character(character) -> void:
    var color = Color('#ffffff')
    var name = 'Stranger'
    if character != null:
        name = character.get('name', 'Stranger')
        color = Color(character.get('color', '#ffffff'))
    else:
        name_label.bbcode_text = ''
        current_name = ''
        return

    #if name != current_name or color != current_color:
    name_label.bbcode_text = ''
    name_label.push_align(RichTextLabel.ALIGN_CENTER)
    name_label.push_color(color)
    name_label.append_bbcode(name)
    current_name = name


func set_speech(text):
    speech_label.bbcode_text = ''
    speech_label.push_align(RichTextLabel.ALIGN_CENTER)
    speech_label.append_bbcode(text)
    speech_label.visible_characters = 0
    while speech_label.visible_characters < len(text):
        speech_label.visible_characters += 1
        yield(get_tree().create_timer(1/100), 'timeout')


func next():
    VM.next()


func _on_started():
    set_process(true)
    visible = true


func _on_ended():
    set_process(false)
    visible = false


func _on_said(who, what, _flush):
    set_character(who)
    set_speech(what)


func _on_option_chosen(which):
    if VM.choose_option(which):
        for i in menu_container.get_children():
            i.queue_free()


func _on_menu(prompt, options: Array):
    if prompt:
        set_character(null)
        set_speech(prompt)

    for option in options:
        var button = MenuOptionButton.instance()
        button.text = option
        button.connect("option_chosen", self, "_on_option_chosen")
        menu_container.add_child(button)
