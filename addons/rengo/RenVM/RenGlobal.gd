extends Node


class Token:
    """Token class contains info about
    token type and its value
    """
    var token_type
    var value
    
    func _init(token_type, value=null):
        self.token_type = token_type
        self.value = value
    
    func _to_string() -> String:
        return "Token(token_type=%s, value=%s)" % [RenConsts.TType_to_display_name[self.token_type], self.value]
