extends Button

signal option_chosen(option)

func _on_Button_pressed():
    # Just for convinience we send button text on press
    emit_signal("option_chosen", text)
