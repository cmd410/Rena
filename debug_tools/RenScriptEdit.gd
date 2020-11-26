extends TextEdit

const COLORS = [Color(0.8, 0, 0.4), Color(0.2, 0.8, 0.2)]

const KEYWORDS = {
    'label': COLORS[0]
   }


func _ready():
    add_color_region("\'", "\'", COLORS[1])
    add_color_region('\"', '\"', COLORS[1])
    for key in KEYWORDS:
        add_keyword_color(key, KEYWORDS[key])

