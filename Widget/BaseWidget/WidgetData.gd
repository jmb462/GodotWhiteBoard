extends Resource
class_name WidgetData

@export var rect : Rect2 = Rect2()
@export var global_rotation : float = 0.0
@export var visible_on_presentation_screen : bool = true
@export var locked : bool = false
@export var editable : bool = true
@export var keep_ratio : bool = false

func store(p_widget : Widget) -> void:
	rect = p_widget.get_rect()
	global_rotation = p_widget.get_global_transform().get_rotation()
	visible_on_presentation_screen = p_widget.visible_on_presentation_screen
	locked = p_widget.locked
	editable = p_widget.editable
	keep_ratio = p_widget.keep_ratio

func setup_widget(p_widget : Widget) -> void:
	p_widget.size = rect.size
	p_widget.size = rect.size
	p_widget.global_rotation = global_rotation
	p_widget.visible_on_presentation_screen = visible_on_presentation_screen
	p_widget.locked = locked
	p_widget.editable = editable
	p_widget.keep_ratio = keep_ratio

func print_data() -> void:
	print("===")
	print("Rect %s" % rect)
	print("global_rotation %s" % global_rotation)
	print("visible_on_presentation_screen %s" % visible_on_presentation_screen)
	print("editable %s" % editable)
	print("keep_ratio %s" % keep_ratio)
