extends Resource
class_name BoardData

@export var size : Vector2 = Vector2()
@export var widgets : Array[WidgetData] = []
@export var uid : int = 0

## Store persistant properties of the board in the BoardData resource.
func store(p_board : Board) -> void:
	uid = p_board.uid
	size = p_board.size	
	for widget : Widget in p_board.get_widgets():
		widgets.push_back(widget.get_data())


## Restore persistant properties of the board from the BoardData resource.
func restore(p_board : Board) -> void:
	p_board.set_deferred("set_size", size)
	p_board.uid = uid
	p_board.restore_widgets(widgets)

func print_data() -> void:
	print("===")
	print("uid: %s" % uid)
	print("size: %s" % size)
	print("widgets: ", widgets)
