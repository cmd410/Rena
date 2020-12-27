extends Button

signal option_chosen(option)

func _on_Button_pressed():
    emit_signal("option_chosen", text)
