extends Action
class_name ActionLayerChange

var layer_from : int = 0
var layer_to : int = 0
var board : Board

func setup(p_board : Board, p_widget : Widget, p_layer_from : int, p_layer_to : int) -> void:
	board = p_board
	widget = p_widget
	layer_from = p_layer_from
	layer_to = p_layer_to

func execute() -> void:
	if is_instance_valid(widget):
		board.set_widget_new_layer(widget, layer_to)

func unexecute() -> void:
	if is_instance_valid(widget):
		board.set_widget_new_layer(widget, layer_from)
