extends Node
class_name RenLexer


const quotes = '\"' + "\'"   # Adding two string because one string messes up syntax highligting in vscode

var valid_id_chars: String = RenConsts.valid_id_chars
var keywords: Dictionary = RenConsts.KEYWORDS
var TOKEN_LOOKUP: Dictionary = RenConsts.TOKEN_LOOKUP


export(String, FILE) var source_file

var lines: PoolStringArray = []

var pos: int = -1  # pos in line
var line: int = 0
var current_line: String
var current_char: String 
var current_indent: int = 0
var last_block_indent: int = -4

var pending_tokens: Array = []


func _ready() -> void:
    if source_file:
        set_source_file(source_file)
        var token = get_next_token()
        while token.token_type != RenToken.types.EOF:
            print(token)
            token = get_next_token()


func has_source() -> bool:
    """Returns True if lexer got non-empty source file
    """
    return not lines.empty()


func read_file() -> String:
    var file: File = File.new()
    file.open(source_file, File.READ)
    
    var text: String = file.get_as_text()
    file.close()
    
    return text


func set_source_file(filename: String) -> void:
    if filename != source_file:
        source_file = filename

        # Reset parameters for each new file
        line = 0
        pos = -1
        current_indent = 0
        last_block_indent = -4
        pending_tokens.clear()
        lines = PoolStringArray()

    # Get text from file
    var text = read_file()
    lines = text.split('\n')
    current_line = lines[line]
    advance()


func error(msg: String = '') -> void:
    """Raises error with some useful message
    """
    var base_msg = '[LexerError] in file {filename}\n\tLine {lineno}: \"{line}\"'
    if msg != '':
        msg = base_msg+ '\n\t' + msg
    else:
        msg = base_msg

    msg = msg.format({
        'filename': source_file,
        'line': current_line,
        'lineno': line + 1,
        'char': current_char,
        'pos': pos
    })

    assert(false, msg)


func update_indent():
    var detented_line = current_line.dedent()
        
    # Skip empty lines and comments
    while detented_line.empty() or detented_line[0] == '#':
        line += 1
        if line > len(lines) - 1:
            current_char = ''  # empty current char for EOF 
            break
        current_line = lines[line]
        detented_line = current_line.dedent()
    
    current_indent = len(current_line) - len(detented_line)
    
    # Push Block start / block end tokens to queue when indent changes
    if current_indent != last_block_indent:
        if current_indent > last_block_indent:                                # Entering new block
            for i in range(floor((current_indent - last_block_indent) / 4)):
                pending_tokens.append(
                    RenToken.new(
                        RenToken.types.BLOCK_START
                    )
                )
        else:                                                                 # Exiting blocks
            for i in range(floor((last_block_indent - current_indent) / 4)):
                pending_tokens.append(
                    RenToken.new(
                        RenToken.types.BLOCK_END
                        )
                    )
        last_block_indent = current_indent


func advance() -> void:
    """Advaces lexer position
    updating current_char variable
    """
    pos += 1
    if pos == 0:
        update_indent()
    if pos > len(current_line) - 1:
        line += 1
        if line > len(lines) - 1:
            current_char = ''
            return
        current_line = lines[line]
        update_indent()
        # reset position in string and set char to newline
        pos = -1
        current_char = '\n'
    else:
        current_char = current_line[pos]


func peek(index: int = 1) -> String:
    """Look up character at position
    relative to current character without consuming it.

    returns empty string if out of line bounds
    """
    var char_index = pos + index
    if 0 > char_index or char_index > len(current_line) - 1:
        return ''
    else:
        return current_line[char_index]


func skip_whitespace() -> void:
    while current_char == ' ':
        advance()


func is_line_end():
    """Retunrs true if current char is either \n or empty
    """
    return current_char == '\n' or current_char.empty()


func number():
    """Parses integer of float number

    return float or int
    """
    var result: String = ''
    var is_float: bool = false

    while not is_line_end():
        if current_char.is_valid_integer():
            result += current_char
            advance()
        elif current_char == '.':
            if is_float:
                error('Error in parsing float number.')
            result += current_char
            is_float = true
            advance()
        elif current_char == '_':
            advance()
        else:
            break
    
    var token: RenToken
    if is_float:
        token = RenToken.new(RenToken.types.FLOAT, float(result))
    else:
        token = RenToken.new(RenToken.types.INTEGER, int(result))
    
    pending_tokens.append(token)
    return pending_tokens.pop_front()


func id():
    """Parses identifiers and keywords
    """
    var result: String = ''
    while not is_line_end() and current_char in valid_id_chars:
        result += current_char
        self.advance()

    var token_type = keywords.get(result, RenToken.types.ID)
    
    pending_tokens.append(RenToken.new(token_type, result))
    
    return pending_tokens.pop_front()


func string():
    """Parses quoted strings
    """
    var result: String = ''
    var string_end: bool = false
    var quote_type: String = current_char
    
    advance()

    while not is_line_end() and not string_end:
        if current_char == '\\':
            self.advance()
            continue
        if self.current_char == quote_type and peek(-1) == '\\':
            result += current_char
            advance()
        elif current_char == quote_type:
            string_end = true
            advance()
            break
        else:
            result += current_char
            advance()

    if not string_end:
        error('String missing closing quote.')
    
    pending_tokens.append(RenToken.new(RenToken.types.STRING, result))

    return pending_tokens.pop_front()


func get_next_token():
    if not pending_tokens.empty():
        return pending_tokens.pop_front()

    while not current_char.empty():
        var character: String = current_char
        if character in ' \t':
            skip_whitespace()
            continue
        
        character = current_char
        if character.is_valid_integer():
            return number()
        elif character in quotes:
            return string()
        elif character.is_valid_identifier():
            return id()
        elif TOKEN_LOOKUP.has(character):
            var two_char_op = character + peek()
            if TOKEN_LOOKUP.has(two_char_op) and len(two_char_op) == 2:
                var current_token = RenToken.new(TOKEN_LOOKUP[two_char_op], two_char_op)
                advance()
                advance()
                return current_token
            else:
                var current_token = RenToken.new(TOKEN_LOOKUP[character], character)
                advance()
                return current_token
        else:
            error('Unexpected character: \"{char}\"')
    
    var end = RenToken.new(RenToken.types.BLOCK_END)
    for i in range(floor(current_indent / 4)):
        pending_tokens.append(end)

    pending_tokens.append(end)
    pending_tokens.append(RenToken.new(RenToken.types.EOF))
    return pending_tokens.pop_front()
