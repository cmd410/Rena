extends Node

signal started()
signal say(who, what, flush)
signal menu(prompt, options)
signal ended()


export(String, FILE) var source_filename


var text: String = ''


func set_text(text: String) -> void:
    self.text = text


func build_ast():
    return RenParser.new(RenLexer.new(self.text)).script().value

