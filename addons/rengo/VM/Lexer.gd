extends RenRef
class_name RenLexer


var lines: PoolStringArray

var lineno: int = 0
var linepos: int = 0

var current_char: String = ''
var current_line: String = ''
var meaningfull: bool

var current_indent: int = 0
var last_indent: int = -4

var queued_tokens: Array = []


func _init(text: String):
    self.lines = text.split('\n')


func get_lexer_state() -> Dictionary:
    var state = {
        'lineno': self.lineno,
        'pos': self.linepos,
        'line': self.current_line
    }
    return state


func error(err_type: String, message: String) -> RenERR:
    var err_info = get_lexer_state()
    err_info['err_type'] = err_type
    err_info['message'] = message
    return RenERR.new(err_info)


func peek(offset: int = 1):
    var peek_index = self.linepos + offset
    if peek_index >= len(self.current_line):
        return ''
    else:
        return self.current_line[peek_index]


func update_indent():
    var dedented_line = current_line.dedent()
    var new_indent: int = len(current_line) - len(dedented_line)

    self.meaningfull = not dedented_line.empty() or dedented_line[0] != '#'

    if not self.meaningfull or new_indent == last_indent:
        return
    
    elif new_indent != self.last_indent:  # Indent changed
        
        self.current_line = dedented_line
        
        # Block start
        if new_indent > self.last_indent:
            var blocks_depth = floor((new_indent - self.last_indent) / 4)
            var block_start = RenToken.new(RenToken.BLOCK_START)
            
            for i in range(blocks_depth):
                self.queued_tokens.push_back(block_start)
        
        # Block end
        else:
            var blocks_depth = floor((self.last_indent - new_indent) / 4)
            var block_end = RenToken.new(RenToken.BLOCK_END)

            for i in range(blocks_depth):
                self.queued_tokens.push_back(block_end)


func advance() -> RenResult:
    if self.lines.empty():
        return error(RenERR.SOURCE_EMPTY, 'Lexer was given empty string')
    
    self.linepos += 1
    if self.linepos >= len(self.current_line):
        self.lineno += 1
        
        if self.lineno >= len(self.lines):
            self.current_line = ''
            self.current_char = ''
        else:
            self.current_line = self.lines[self.lineno]

        self.linepos = -1
        self.queued_tokens.push_back(RenToken.new(RenToken.EOL))
        
        update_indent()
    else:
        self.current_char = self.current_line[self.linepos]
    
    return RenOK.new(0)
