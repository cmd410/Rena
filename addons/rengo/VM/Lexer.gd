extends RenRef
class_name RenLexer


signal exception(err)
signal advanced(chr)
signal newline()
signal new_token(token)
signal reached_eof()
signal block_enter()
signal block_exit()


var lines: PoolStringArray

var lineno: int = 0
var linepos: int = -1

var current_char: String = ''
var current_line: String = ''
var meaningfull: bool

var current_indent: int = 0
var last_indent: int = -4

var queued_tokens: Array = []
var depleted: bool = false

const VALID_IDS = ('qwertyuiopasdfghjklzxcvbnm' +
                   'QWERTYUIOPASDFGHJKLZXCVBNM' +
                   '1234567890_')


func _init(text: String):
    self.lines = text.split('\n')
    if not self.lines.empty():
        self.current_line = self.lines[0]


func get_lexer_state() -> Dictionary:
    var state = {
        'lineno': self.lineno + 1,
        'pos': self.linepos,
        'line': self.current_line
    }
    return state


func error(err_type: String, message: String) -> RenERR:
    var err_info = get_lexer_state()
    err_info['err_type'] = err_type
    err_info['message'] = message
    var err = RenERR.new(err_info)
    emit_signal('exception', err)
    return err


func token_notify(token: RenToken):
    emit_signal('new_token', token)
    match token.token_type:
        RenToken.EOL:
            emit_signal('newline')
        RenToken.EOF:
            emit_signal('reached_eof')
            self.depleted = true
        RenToken.BLOCK_START:
            emit_signal('block_enter')
        RenToken.BLOCK_END:
            emit_signal('block_exit')


func peek(offset: int = 1) -> String:
    var peek_index = self.linepos + offset
    if peek_index >= len(self.current_line):
        return ''
    else:
        return self.current_line[peek_index]


func skip_spaces():
    while self.current_char == ' ':
        advance()


func update_indent():
    var dedented_line = current_line.dedent()
    var new_indent: int = len(current_line) - len(dedented_line)
    
    if not dedented_line.empty():
        self.meaningfull = dedented_line[0] != '#'
    else:
        self.meaningfull = false

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
        
        self.last_indent = self.current_indent
        self.current_indent = new_indent

    
func hop(n: int) -> RenResult:
    for i in range(n):
        var res = advance()
        if res is RenERR:
            return res
    return RenOK.new(0)


func advance() -> RenResult:
    if self.lines.empty():
        return error(RenERR.SOURCE_EMPTY, 'Lexer was given empty string')

    self.linepos += 1
    if self.linepos == -1:
        self.current_char = '\n'
        return RenOK.new(0)
    # If out of line
    if self.linepos >= len(self.current_line):
        self.lineno += 1
        
        # If lines ended
        if self.lineno >= len(self.lines):
            self.current_line = ''
            self.current_char = ''
            self.current_indent = -4
            return RenOK.new(0)
        else:
            self.current_line = self.lines[self.lineno]

        self.linepos = -2
        self.current_char = '\n'
    else:
        self.current_char = self.current_line[self.linepos]
    
    emit_signal('advanced', self.current_char)
    return RenOK.new(0)


func number() -> RenResult:
    var result: String = self.current_char
    var is_float: bool = false
    while true:
        var next_char = peek()
        if (next_char.is_valid_integer() or next_char in ['_','.']):
            advance()
        else:
            break

        if self.current_char.is_valid_integer():
            result += self.current_char
        elif self.current_char == '_':
            continue
        elif self.current_char == '.':
            if is_float:
                return error(RenERR.PARSING_ERROR, 'Failed to parse float number, too many dots.')
            is_float = true
            result += self.current_char
        else:
            break

    if is_float:
        return RenOK.new(RenToken.new(RenToken.FLOAT, float(result)))
    else:
        return RenOK.new(RenToken.new(RenToken.INT, int(result)))


func id() -> RenResult:
    var result: String = ''
    while self.current_char in VALID_IDS:
        result += self.current_char
        advance()
    return RenOK.new(result)


func string():
    # TODO Add separate multiline support
    var quote_type = self.current_char
    var is_multiline = false
    while peek() == quote_type:
        advance()
        quote_type += self.current_char
        if len(quote_type) == 3:
            is_multiline = true
            break
    if not is_multiline and len(quote_type) > 1:
        return error(RenERR.PARSING_ERROR, """Too many quotes for single line, too less for multiline.
                                              Consider escaping quotes with \\ if you want to include them in the string.""")
    advance()
    var result: String = ''
    var end: bool = false
    var last_char: String = ''
    while true:
        match self.current_char:
            "\'", '\"':
                if last_char == '\\':
                    result += self.current_char
                    last_char = self.current_char
                    advance()
                elif self.current_char == quote_type:
                    end = true
                    advance()
                    break
                else:
                    result += self.current_char
                    last_char = self.current_char
                    advance()
            '\\':
                if last_char == '\\':
                    result += self.current_char
                    last_char = ''
                    advance()
                else:
                    var c = ''
                    var l = '\\'
                    match peek():
                        'n':
                            c = '\n'
                            l = c
                            advance()
                        't':
                            c = '\t'
                            l = c
                            advance()
                        'r':
                            c = '\r'
                            l = c
                            advance()
                        'u':
                            advance()
                            var a = peek(1) + peek(2)
                            if not len(a) == 2:
                                return error(
                                        RenERR.PARSING_ERROR,
                                        'Cannot parse unicode character \\u%s' % [a]
                                    )
                            var b = peek(3) + peek(4)
                            if not len(b) == 2:
                                return error(
                                        RenERR.PARSING_ERROR,
                                        'Cannot parse unicode character \\u%s' % [a+b]
                                    )
                            hop(4)
                            if not (a.is_valid_hex_number() and b.is_valid_hex_number()):
                                return error(
                                        RenERR.PARSING_ERROR,
                                        'Cannot parse unicode character \\u%s' % [a+b]
                                    )
                            c = char(('0x' + a + b).hex_to_int())
                            l = c
                        'x':
                            advance()
                            var a = peek(1) + peek(2)
                            if not len(a) == 2:
                                return error(
                                        RenERR.PARSING_ERROR,
                                        'Cannot parse unicode character \\u%s' % [a]
                                    )
                            hop(2)
                            if not (a.is_valid_hex_number()):
                                return error(
                                        RenERR.PARSING_ERROR,
                                        'Cannot parse ascii character \\x%s' % [a]
                                    )
                            c = char(('0x' + a).hex_to_int())
                            l = c
                    result += c
                    last_char = l
                    advance()
            _:
                result += self.current_char
                last_char = self.current_char
                advance()
    if not end:
        return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected EOF while parsing string')
    else:
        return RenOK.new(RenToken.new(RenToken.STR, result))


func get_next_token() -> RenResult:
    var token: RenToken = null
    # Check if we got some tokens to be sent already
    if self.queued_tokens:
        token = self.queued_tokens.pop_front()
    else:
        if self.lineno == 0 and self.linepos == -1:
            update_indent()
        # If no tokens go to next characters
        var res = advance()
        if res is RenERR:
            return res
        
        if self.current_char == ' ':
            skip_spaces()

        if not self.current_char.empty():
            # Parse number if first char is integer
            if self.current_char.is_valid_integer():
                var num = number()
                if num is RenERR:
                    return num
                self.queued_tokens.append(num.value)
            
            # Could it be identifier?
            elif self.current_char.is_valid_identifier():
                var iden = id().value
                var type = RenToken.ID
                if RenToken.KEYWORDS.has(iden):
                    type = RenToken.KEYWORDS[iden]
                self.queued_tokens.append(RenToken.new(type, iden))
            
            elif self.current_char in RenToken.QUOTE:
                var result = string()
                if result is RenERR:
                    return result
                self.queued_tokens.append(result.value)
            # If its none of above, look it up in operators then
            else:
                var token_type = null
                var token_value = null
                var double_char = self.current_char + peek()

                match double_char:
                    '//', '**':
                        token_type = double_char
                        token_value = double_char
                        advance()
                    _:
                        match self.current_char:
                            '+', '-', '*', '/', '%', '(', ')', '=':
                                token_type = self.current_char
                                token_value = self.current_char
                            '\n':
                                token_type = RenToken.EOL
                            _:
                                return error(RenERR.TOKEN_UNKNOWN, 'Lexer got unknown token: \"%s\"' % [self.current_char])

                self.queued_tokens.push_back(RenToken.new(token_type, token_value))
                
                # we need to update indent on every new line
                if token_type == RenToken.EOL:
                    update_indent()
            token = self.queued_tokens.pop_front()
        else:
            # If line is empty we reached EOF
            # Close all blocks before sending EOF token
            var end = RenToken.new(RenToken.BLOCK_END)
            for i in range(floor((self.current_indent + 4)/4) + 1):
                self.queued_tokens.push_back(end)
            
            self.queued_tokens.push_back(RenToken.new(RenToken.EOF))
            token = self.queued_tokens.pop_front()
    
    token_notify(token)
    return RenOK.new(token)
