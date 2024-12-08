extends Action
class_name ActionVisibility

func setup(p_widget : Widget) -> void:
	widget = p_widget

func undo() -> void:
	if is_instance_valid(widget):
		widget._on_buttons_toggle_visible_pressed(false)
		widget.synchronize()
	
func redo() -> void:
	if is_instance_valid(widget):
		widget._on_buttons_toggle_visible_pressed(false)
		widget.synchronize()
