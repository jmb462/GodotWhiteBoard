extends Action
class_name ActionRectChange

var widget_rect_from : Rect2 = Rect2()
var widget_rect_to : Rect2 = Rect2()

func setup(p_widget : Widget, p_widget_rect_from : Rect2, p_widget_rect_to : Rect2) -> void:
	widget = p_widget
	widget_rect_from = p_widget_rect_from
	widget_rect_to = p_widget_rect_to


func undo() -> void:
	if is_instance_valid(widget):
		widget.position = widget_rect_from.position
		widget.size = widget_rect_from.size
		widget.synchronize()
	
func redo() -> void:
	if is_instance_valid(widget):
		widget.position = widget_rect_to.position
		widget.size = widget_rect_to.size
		widget.synchronize()
