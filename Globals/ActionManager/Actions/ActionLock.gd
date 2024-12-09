extends Action
class_name ActionLock

func setup(p_widget : Widget) -> void:
	widget = p_widget

func execute() -> void:
	if is_instance_valid(widget):
		widget.toggle_lock()

func unexecute() -> void:
	if is_instance_valid(widget):
		widget.toggle_lock()
