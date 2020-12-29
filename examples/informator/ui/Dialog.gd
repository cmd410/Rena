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

var should_flush: bool = true

func _ready():
    set_process(false)   # Disable _process when not needed
    if VirtualMachine:
        set_vm(get_node(VirtualMachine))


func set_vm(vm):
    # Set virtual machine and connect signals from it
    VM = vm
    
    # Emited when dialog starts and ends respectively
    VM.connect("started", self, "_on_started")
    VM.connect("ended", self, "_on_ended")

    # Emited when a say statement occurs, sends who, what, and flush
    VM.connect("said", self, "_on_said")

    # Emited on menus, sends menu prompt and options available
    VM.connect("menu", self, "_on_menu")


func _process(_delta):
    # Process continue button
    if Input.is_action_just_pressed("ui_accept"):
        next()


func set_character(character) -> void:
    # Gets character name an color from dictionary and pushes it to name label
    
    # Defaults
    var color = Color('#ffffff')
    var name = 'Stranger'
    
    if character != null:
        # Get name an color
        name = character.get('name', 'Stranger')
        color = Color(character.get('color', '#ffffff'))
    
    else:
        # Character is null, author speech
        name_label.bbcode_text = ''
        current_name = ''
        return
    
    # Set name label text 
    name_label.bbcode_text = ''
    #name_label.push_align(RichTextLabel.ALIGN_CENTER)
    name_label.push_color(color)
    
    assert(not name_label.append_bbcode(name), 'Failed to append bbcode')
    
    current_name = name


func set_speech(text):
    # Set speech text
    speech_label.bbcode_text = ''
    #speech_label.push_align(RichTextLabel.ALIGN_CENTER)
    
    assert(not speech_label.append_bbcode(text), 'Failed to append bbcode')
    
    # imitate typewriter
    speech_label.visible_characters = 0
    while speech_label.visible_characters < len(text):
        speech_label.visible_characters += 1
        yield(get_tree().create_timer(1/100), 'timeout')


func add_speech(text):
    assert(not speech_label.append_bbcode(' ' + text))
    while speech_label.visible_characters < len(speech_label.text):
        speech_label.visible_characters += 1
        yield(get_tree().create_timer(1/100), 'timeout')


func next():
    # Just call vm for next statement
    VM.next()


func _on_started():
    # When vm starts dialog
    set_process(true)  # Start processing next button
    visible = true     # Set dialog ui visible


func _on_ended():
    # When vm ends dialog
    set_process(false)  # Stop processing next button
    visible = false     # Hide dialog ui


func _on_said(who, what, flush):
    if should_flush:
        set_character(who)
        set_speech(what)
    else:
        add_speech(what)
    should_flush = flush


func _on_option_chosen(which):
    # When option button is pressed
    
    if VM.choose_option(which):
        # If option chosen is a valid option, clear menu
        for i in menu_container.get_children():
            i.queue_free()


func _on_menu(prompt, options: Array):
    # When menu should popup

    # Set menu prompt
    if prompt:
        set_character(null)
        set_speech(prompt)
    
    # Spawn option buttons
    for option in options:
        
        var button = MenuOptionButton.instance()
        button.text = option
        button.connect("option_chosen", self, "_on_option_chosen")
        menu_container.add_child(button)
