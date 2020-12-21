extends Button

signal option_chosen(text)

func _ready():
    connect("pressed", self, "_on_pressed")


func _on_pressed():
    emit_signal("option_chosen", self.text)
