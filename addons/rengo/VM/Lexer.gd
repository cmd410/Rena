extends RenRef
class_name RenLexer


signal exception(err)
signal advanced(chr)
signal newline()
signal new_token(token)
signal reached_eof()
signal block_enter()
signal block_exit()


var text: String

var linepos: int = 0
var lineno: int = 0
var pos: int = 0
var indent_stack: Array = []
var queued_exits: Array = []
var current_char: String = ''

var started: bool = false
var depleted: bool = false


const VALID_IDS = ('qwertyuiopasdfghjklzxcvbnm' +
                   'QWERTYUIOPASDFGHJKLZXCVBNM' +
                   '1234567890_')

var enter_token = RenToken.new(RenToken.BLOCK_START)
var exit_token = RenToken.new(RenToken.BLOCK_END)


func _init(text: String):
    self.text = text
    if not self.text.empty():
        self.current_char = self.text[0]


func get_lexer_state() -> Dictionary:
    var state = {
        'lineno': self.lineno + 1,
        'pos': self.linepos,
        'line': self.text.split('\n')[self.lineno]
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
    var peek_index = self.pos + offset
    if peek_index >= len(self.text):
        return ''
    else:
        return self.text[peek_index]


func skip_spaces():
    while self.current_char == ' ':
        advance()


func get_indent() -> int:
    var indent = self.indent_stack[-1]
    var i = 0
    if self.current_char == ' ' and peek(-1) == '\n':
        while peek(i) == ' ':
            i += 1
        if peek(i) != '\n':
            indent = i
        else:
            hop(i)
    return indent
        

func hop(n: int) -> RenResult:
    for i in range(n):
        var res = advance()
        if res is RenERR:
            return res
    return RenOK.new(0)


func advance() -> RenResult:
    self.pos += 1
    self.linepos +=1
    if self.current_char == '\n':
        self.lineno += 1
        self.linepos = 0
    
    if self.pos >= len(self.text):
        self.current_char = ''
        return RenOK.new(0)
    
    self.current_char = self.text[self.pos]

    emit_signal('advanced', self.current_char)
    return RenOK.new(0)


func number() -> RenResult:
    var result: String = ''
    var is_float: bool = false
    while true:
        if self.current_char.is_valid_integer():
            result += self.current_char
            advance()
        elif self.current_char == '_':
            advance()
            continue
        elif self.current_char == '.':
            if is_float:
                return error(RenERR.PARSING_ERROR, 'Failed to parse float number, too many dots.')
            is_float = true
            result += self.current_char
            advance()
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
    
    if RenToken.KEYWORDS.has(result):
        return RenOK.new(RenToken.new(RenToken.KEYWORDS[result], result))
    else:
        return RenOK.new(RenToken.new(RenToken.ID, result))


func string() -> RenResult:
    var quote_type = self.current_char
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
                            advance()
                        't':
                            c = '\t'
                            advance()
                        'r':
                            c = '\r'
                            advance()
                        'u', 'x':
                            advance()
                            var form = self.current_char
                            var a = peek(1) + peek(2)
                            var b = ''
                            var ml = 4
                            if form == 'u':
                                b = peek(3) + peek(4)
                                ml = 6
                            var hex = '0x' + a + b
                            print(hex, ' ' ,ml, ' ', len(hex))
                            hop(ml-2)
                            if not (hex.is_valid_hex_number(true) and len(hex) == ml):
                                return error(
                                        RenERR.PARSING_ERROR,
                                        'Cannot parse character \"\\%s%s\"' % [form, a+b]
                                    )
                            c = char(hex.hex_to_int())

                    result += c
                    l = c
                    last_char = l
                    advance()
            '':
                return error(RenERR.PARSING_ERROR, 'Unexpected EOF while parsing string')
            _:
                result += self.current_char
                last_char = self.current_char
                advance()
    if not end:
        return error(RenERR.TOKEN_UNEXPECTED, 'Unexpected EOF while parsing string')
    else:
        return RenOK.new(RenToken.new(RenToken.STR, result))


func get_next_token() -> RenResult:
    if not self.started:
        self.indent_stack.push_back(0)
        self.started = true
        return RenOK.new(enter_token)
    
    if not queued_exits.empty():
        return RenOK.new(queued_exits.pop_front())
    
    while not self.current_char.empty():
        var c = self.current_char
        if not c in [' ', '\n']:
            if peek(-1) == '\n':
                while len(self.indent_stack) > 1:
                    self.indent_stack.pop_back()
                    return RenOK.new(exit_token)
        
        var doubleop = c + peek(1)
        if RenToken.DOUBLEOPS.has(doubleop):
            var token_type = RenToken.DOUBLEOPS[doubleop]
            hop(2)
            return RenOK.new(RenToken.new(token_type))
        match c:
            ' ':
                if peek(-1) == '\n':
                    var indent = get_indent()
                    hop(indent)
                    
                    if indent > indent_stack[-1]:
                        indent_stack.push_back(indent)
                        return RenOK.new(enter_token)
                    
                    elif indent < indent_stack[-1]:

                        while indent != indent_stack[-1]:
                            indent_stack.pop_back()
                            queued_exits.push_back(exit_token)
                            if indent_stack[-1] == 0 and indent != 0:
                                return error('IndentedationError', 'Indentation does not match any block')
                        return RenOK.new(queued_exits.pop_back())
                else:
                    skip_spaces()
            
            '1', '2', '3', '4', '5', '6', '7', '8', '9', '0':
                return number()
            '+', '-', '*', '/', '%', '=', '(', ')', '[', ']', '{', '}', ':', '^', '|', '&', '<', '>', '$':
                advance()
                return RenOK.new(RenToken.new(c))
            '\n':
                advance()
                return RenOK.new(RenToken.new(RenToken.EOL))

            '\"', "\'":
                return string()
            _:
                if c.is_valid_identifier():
                    return id()
                else:
                    return error(RenERR.TOKEN_UNEXPECTED, 'Lexer got unexpected character: "%s"' % [c])
        #advance()
    while not self.indent_stack.empty():
        self.indent_stack.pop_back()
        return RenOK.new(exit_token)
    
    self.depleted = true
    return RenOK.new(RenToken.new(RenToken.EOF))
