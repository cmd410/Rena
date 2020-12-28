tool
extends TextEdit

const COLORS = [
    Color(0.8, 0, 0.4), Color(0.2, 0.8, 0.2), Color(0.9, 0.6, 0.25),
    Color(0.83, 0.24, 0.2)
]

const KEYWORDS = {
    'label': COLORS[2],
    'menu': COLORS[2],
    'define': COLORS[2],
    'default': COLORS[2],
    '$': COLORS[2],
    'if': COLORS[2],
    'elif': COLORS[2],
    'else': COLORS[2],
    'jump': COLORS[2],
    'return': COLORS[2],
    'call': COLORS[2],
    'in': COLORS[2],
    'and': COLORS[3],
    'or': COLORS[3],
    'True': COLORS[3],
    'False': COLORS[3],
    'not': COLORS[3],
    'do': COLORS[3]
   }


var current_save_path = ''
var is_dirty: bool = false


func _ready():
    setup_highlighting()
    connect("text_changed", self, "_on_text_changed")
    

func _on_text_changed():
    is_dirty = true


func setup_highlighting():
    clear_colors()
    
    add_color_region("\'", "\'", COLORS[1])
    add_color_region('\"', '\"', COLORS[1])
    add_color_region('#', '', Color(0.4, 0.4, 0.4), true)
    for key in KEYWORDS:
        add_keyword_color(key, KEYWORDS[key])
