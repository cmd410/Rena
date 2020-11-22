extends Node
class_name RenInterpreter

export(String, FILE) var source_file

onready var parser = get_node("Parser") as RenParser

func _ready():
    if source_file:
        parser.init(source_file)
        parser.parse()
