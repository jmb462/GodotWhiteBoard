extends Action
class_name ActionToggleVisibility

func setup(p_widget : Widget) -> void:
	widget = p_widget

func execute() -> void:
	if is_instance_valid(widget):
		widget.toggle_visibility()

func unexecute() -> void:
	if is_instance_valid(widget):
		widget.toggle_visibility()
