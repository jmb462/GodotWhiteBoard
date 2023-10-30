extends Resource
class_name BoardsData

@export var boards : Array[BoardData] = []

## Store persistant properties of all the boards in the BoardsData resource.
func store(p_boards : Array[Board]) -> void:
	for board : Board in p_boards:
		boards.push_back(board.get_data())

## Restore persistant properties of all the boards from the BoardsData resource.
#func restore(p_board : Board) -> void:
	#pass

func print_data() -> void:
	print("===")
	print("boards ", boards)
