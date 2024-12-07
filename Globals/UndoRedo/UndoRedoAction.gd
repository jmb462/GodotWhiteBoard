extends Resource
class_name UndoRedoAction

var action_name : String = ""

var widget : Widget = null
var widget_rect_from : Rect2 = Rect2()
var widget_rect_to : Rect2 = Rect2()
var widget_rotation_degrees_from : float = 0.0
var widget_rotation_degrees_to : float = 0.0


func dispatch_args(p_args : Array) -> void:
	match action_name:
		"widget_rect_changed":
			widget = p_args[0]
			widget_rect_from = p_args[1]
			widget_rect_to = p_args[2]
		"widget_rotated":
			widget = p_args[0]
			widget_rotation_degrees_from = p_args[1]
			widget_rotation_degrees_to = p_args[2]
		"visibility_changed":
			widget = p_args[0]
		"locked_changed":
			widget = p_args[0]

func undo():
	if is_instance_valid(widget):
		match action_name:
			"widget_rect_changed":
				widget.position = widget_rect_from.position
				widget.size = widget_rect_from.size
			"widget_rotated":
				widget.rotation_degrees = widget_rotation_degrees_from
			"visibility_changed":
				widget.toggle_visibility()
			"locked_changed":
				print("toogle locked undo")
				widget.toggle_lock()
				
		widget.synchronize()
	
func redo():
	if is_instance_valid(widget):
		match action_name:
			"widget_rect_changed":
				widget.position = widget_rect_to.position
				widget.size = widget_rect_to.size
			"widget_rotated":
				widget.rotation_degrees = widget_rotation_degrees_to
			"visibility_changed":
				widget.toggle_visibility()
			"locked_changed":
				widget.toggle_lock()
		widget.synchronize()
