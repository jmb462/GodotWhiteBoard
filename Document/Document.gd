extends Resource
class_name Document

@export var document_info : DocumentInfo = null
@export var boards : Array[BoardData] = []

func _init() -> void:
	document_info = DocumentInfo.new()

## Returns document unique identifier
func get_uid() -> int:
	return document_info.uid

func set_uid(p_uid : int) -> void:
	document_info.uid = p_uid

func set_file_name(p_name : String) -> void:
	document_info.file_name = p_name

## Store persistant properties of all the boards in the Document resource.
func store(p_boards : Array[Board]) -> void:
	boards.clear()
	for board : Board in p_boards:
		boards.push_back(board.get_data())

## Restore persistant properties of all the boards from the Document resource.
func restore(p_board : Board) -> void:
	print(p_board)

## Returns filename if exists or timestamp (YYYY/MM/DD HH:MM)
func get_formated_file_name() -> String:
	return document_info.get_formated_file_name()

func get_document_path() -> String:
	if resource_path.begins_with("user://"):
		return resource_path.get_base_dir()
	return "%s/%s" % [G.ROOT_DOCUMENT_FOLDER, get_uid()]

func get_preview_path(p_index : int) -> String:
	if p_index >= boards.size():
		return ""
	return get_document_path() + '/' +str(boards[p_index].uid) + '_thumbnail.jpg'

func is_empty() -> bool:
	if boards.size() == 1:
		if boards[0].widgets.size() == 0:
			return true
	return false
