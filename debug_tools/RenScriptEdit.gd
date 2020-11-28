extends TextEdit

const COLORS = [
    Color(0.8, 0, 0.4), Color(0.2, 0.8, 0.2), Color(0.9, 0.6, 0.25),
    Color(0.83, 0.24, 0.2)
]

const KEYWORDS = {
    'label': COLORS[0],
    'menu': COLORS[0],
    'define': COLORS[2],
    'default': COLORS[2],
    'if': COLORS[2],
    'elif': COLORS[2],
    'else': COLORS[2],
    'and': COLORS[3],
    'or': COLORS[3]
   }


func _ready():
    add_color_region("\'", "\'", COLORS[1])
    add_color_region('\"', '\"', COLORS[1])
    for key in KEYWORDS:
        add_keyword_color(key, KEYWORDS[key])

