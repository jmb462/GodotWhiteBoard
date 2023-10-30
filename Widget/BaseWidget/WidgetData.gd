extends Resource
class_name WidgetData

@export var rect : Rect2 = Rect2()
@export var global_rotation : float = 0.0
@export var visible_on_presentation_screen : bool = true
@export var locked : bool = false
@export var editable : bool = true
@export var keep_ratio : bool = false
@export var z_index : int = 0

## Store persistant properties of the widget in the WidgetData resource.
func store(p_widget : Widget) -> void:
	rect = p_widget.get_rect()
	print(rect)
	global_rotation = p_widget.get_global_transform().get_rotation()
	print(global_rotation)
	visible_on_presentation_screen = p_widget.visible_on_presentation_screen
	locked = p_widget.locked
	editable = p_widget.editable
	keep_ratio = p_widget.keep_ratio
	z_index = p_widget.z_index
	

## Restore persistant properties of the widget from the WidgetData resource.
func restore(p_widget : Widget) -> void:
	p_widget.position = rect.position
	p_widget.size = rect.size
	p_widget.rotation = global_rotation
	p_widget.visible_on_presentation_screen = visible_on_presentation_screen
	p_widget.locked = locked
	p_widget.editable = editable
	p_widget.keep_ratio = keep_ratio
	p_widget.z_index = z_index

func print_data() -> void:
	print("===")
	print("Rect %s" % rect)
	print("global_rotation %s" % global_rotation)
	print("visible_on_presentation_screen %s" % visible_on_presentation_screen)
	print("editable %s" % editable)
	print("keep_ratio %s" % keep_ratio)
	print("z_index %s" % z_index)
