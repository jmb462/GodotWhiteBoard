extends Widget
class_name GroupWidget

@onready var container : Control = $Container

func _ready() -> void:
	buttons.hide_button_size()
	buttons.hide_button_color()
	buttons.hide_button_resize()

func _on_resized() -> void:
	super()
