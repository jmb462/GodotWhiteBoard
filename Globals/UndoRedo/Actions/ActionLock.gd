extends Action
class_name ActionLock

func setup(p_widget : Widget) -> void:
	widget = p_widget

func undo() -> void:
	if is_instance_valid(widget):
		print("toggle locked from undo")
		widget._on_buttons_locked_pressed(false)
		widget.synchronize()
	
func redo() -> void:
	if is_instance_valid(widget):
		print("toggle locked from redo")
		widget._on_buttons_locked_pressed(false)
		widget.synchronize()
