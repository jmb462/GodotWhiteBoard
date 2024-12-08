extends Action
class_name ActionRotate


var rotation_degrees_from : float = 0.0
var rotation_degrees_to : float = 0.0
var widget_pivot_offset : Vector2 = Vector2()

func setup(p_widget : Widget, p_rotation_degrees_from : float, p_rotation_degrees_to : float, p_pivot_offset : Vector2 ) -> void:
	widget = p_widget
	rotation_degrees_from = p_rotation_degrees_from
	rotation_degrees_to = p_rotation_degrees_to
	widget_pivot_offset = p_pivot_offset

func undo() -> void:
	if is_instance_valid(widget):
		widget.rotation_degrees = rotation_degrees_from
		widget.synchronize()
	
func redo() -> void:
	if is_instance_valid(widget):
		widget.rotation_degrees = rotation_degrees_to
		widget.synchronize()