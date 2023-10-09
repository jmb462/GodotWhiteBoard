extends Node

enum ACTION { NONE, MOVE, RESIZE, COLOR, TEXT_SIZE, CLOSE, TOGGLE_VISIBLE }
enum RESIZE { NONE, LEFT, RIGHT, TOP, BOTTOM, BOTH}
enum COLOR { BLACK, RED, GREEN, BLUE }

var color : Array[Color] = [Color.BLACK, Color("#F44336"), Color("#4CAF50"), Color("#2196F3")]
