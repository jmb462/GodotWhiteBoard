extends Node

enum BOARD_MODE { NONE, SELECT, TEXT_POSITION, TEXT_SIZE, PEN, IMAGE_POSITION, IMAGE_SIZE, PASTE_IMAGE, PASTE_TEXT}
enum ACTION { NONE, MOVE, RESIZE, ROTATE, COLOR, TEXT_SIZE, CLOSE, TOGGLE_VISIBLE }
enum RESIZE { NONE, LEFT, RIGHT, TOP, BOTTOM, BOTH}

enum COLOR { BLACK, RED, GREEN, BLUE }


# Position markers, ordered clockwise
enum MARKER { TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, MIDDLE}


var color : Array[Color] = [Color.BLACK, Color("#F44336"), Color("#4CAF50"), Color("#2196F3")]

func debug_action(p_action : ACTION) -> void:
	print(ACTION.keys()[p_action])
	
