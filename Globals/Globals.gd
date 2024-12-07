extends Node

enum BOARD_MODE { NONE, SELECT, TEXT_POSITION, TEXT_SIZE, PEN, IMAGE_POSITION, IMAGE_SIZE, PASTE_IMAGE, PASTE_TEXT}
enum ACTION { NONE, MOVE, RESIZE, ROTATE, COLOR, TEXT_SIZE, CLOSE, TOGGLE_VISIBLE }
enum RESIZE { NONE, LEFT, RIGHT, TOP, BOTTOM, BOTH}

enum COLOR { BLACK, RED, GREEN, BLUE }


# Position markers, ordered clockwise
enum MARKER { TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT, MIDDLE}

const ROOT_DOCUMENT_FOLDER : String = "user://Documents/"
const DEFAULT_FOLDER_PATH : String = "user://Documents/"
const DOCUMENT_FILE_NAME : String = "document.tres"
const THUMBNAIL_FILE_SUFFIX : String = "_thumbnail.jpg"
const EMPTY_THUMBNAIL : String = "res://Assets/empty_board_thumbnail.jpg"
const COLOR_BLACK : Color = Color.BLACK
const COLOR_RED : Color = Color("#F44336")
const COLOR_GREEN : Color = Color("#4CAF50")
const COLOR_BLUE : Color = Color("#2196F3")

const COPIED_SUFFIX : String = " - Copy"

const HEIGHT_MARGIN : int = 20
const WIDTH_MARGIN : int = 40

const BOARD_GROUP : String = "board_page"
const DOCUMENTS_GROUP : String = "documents_page"

var color : Array[Color] = [COLOR_BLACK, COLOR_RED, COLOR_GREEN, COLOR_BLUE]

var document_folder_path : String = DEFAULT_FOLDER_PATH

func set_document_folder_path(p_document : Document) -> void:
	document_folder_path = p_document.get_document_path()

func get_document_folder_path() -> String:
	return document_folder_path

func get_document_path() -> String:
	return "%s/%s" % [G.document_folder_path, DOCUMENT_FILE_NAME]

func get_image_path(p_image_uid : int) -> String:
	return G.document_folder_path + "/%s.png" % p_image_uid

func get_board_thumbnail_path(p_board_uid : int) -> String:
		return "%s/%s%s" % [G.document_folder_path, p_board_uid, THUMBNAIL_FILE_SUFFIX]
		
func debug_action(p_action : ACTION) -> void:
	print(get_action_name(p_action))
	
func get_action_name(p_action : ACTION) -> String:
	return ACTION.keys()[p_action]
