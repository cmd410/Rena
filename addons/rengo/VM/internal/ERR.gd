extends RenResult
class_name RenERR


# Error types
const TOKEN_UNEXPECTED = 'UnexpectedToken'
const TOKEN_UNKNOWN = 'UnknownToken'
const SOURCE_EMPTY = 'EmptySource'
const PARSING_ERROR = 'ParsingError'
const CODING_ERROR = 'DeveloperIsStupidError'


var err_data: Dictionary


func _init(err_data: Dictionary):
    self.err_data = err_data


func _to_string():
    return """
    {err_type}
    file: {file}
    lineno: {lineno}
    pos: {pos}
    
    {line}
    {message}
    """.format(self.err_data)
