extends Action
class_name ActionRectChange

var widget_rect_from : Rect2 = Rect2()
var widget_rect_to : Rect2 = Rect2()

func setup(p_widget : Widget, p_widget_rect_from : Rect2, p_widget_rect_to : Rect2) -> void:
	widget = p_widget
	widget_rect_from = p_widget_rect_from
	widget_rect_to = p_widget_rect_to


func execute() -> void:
	if is_instance_valid(widget):
		widget.set_new_rect(widget_rect_to)
	
func unexecute() -> void:
	if is_instance_valid(widget):
		widget.set_new_rect(widget_rect_from)
