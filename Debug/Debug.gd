extends Control

@onready var text_edit = $TextEdit

func add(p_text : String, value : Variant) -> void:
	text_edit.text += "\n%s : %s" % [p_text, value]
	text_edit.scroll_vertical = 10000
func clear() -> void:
	text_edit.text = ''
