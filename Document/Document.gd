extends Resource
class_name Document

@export var time_created : Dictionary = Dictionary()
## Default file name will be a timestamp
@export var file_name : String = ""
## Unique document identifier
@export var uid : int = 0

@export var boards : Array[BoardData] = []

func _init() -> void:
	if uid == 0:
		uid = ResourceUID.create_id()
	if time_created.is_empty():
		time_created = Time.get_datetime_dict_from_system()
		

## Returns document unique identifier
func get_uid() -> int:
	return uid

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
	if file_name.is_empty():
		var timestamp : Array = [time_created.year, time_created.month , time_created.day, time_created.hour, time_created.minute]
		return "%04d/%02d/%02d %02d:%02d"%timestamp
	return file_name

func get_document_path() -> String:
	if resource_path.begins_with("user://"):
		return resource_path.get_base_dir()
	return "user://Documents/%s/" % uid

func get_preview_path(p_index : int) -> String:
	if p_index >= boards.size():
		return ""
	return get_document_path() + '/' +str(boards[p_index].uid) + '_thumbnail.jpg'

func is_empty() -> bool:
	if boards.size() == 1:
		if boards[0].widgets.size() == 0:
			return true
	return false
