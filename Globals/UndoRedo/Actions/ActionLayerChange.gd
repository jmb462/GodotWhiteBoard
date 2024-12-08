extends Action
class_name ActionLayerChange

var widget_layer_from : int = 0
var widget_layer_to : int = 0

func setup(p_widget : Widget, p_widget_layer_from : int, p_widget_layer_to : int) -> void:
	widget = p_widget
	widget_layer_from = p_widget_layer_from
	widget_layer_to = p_widget_layer_to

func undo() -> void:
	if is_instance_valid(widget):
		widget.emit_signal("layer_change_requested", widget, widget_layer_from - widget_layer_to, false)

func redo() -> void:
	if is_instance_valid(widget):
		widget.emit_signal("layer_change_requested", widget, widget_layer_to - widget_layer_from, false)
