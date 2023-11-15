extends Resource
class_name DocumentInfo

@export var date_created : Dictionary = Dictionary()

@export var last_modified : Dictionary = Dictionary()

## Default file name will be a timestamp
@export var file_name : String = ""
## Unique document identifier
@export var uid : int = 0


func _init() -> void:
	if uid == 0:
		uid = ResourceUID.create_id()
	if date_created.is_empty():
		date_created = Time.get_datetime_dict_from_system()

## Returns filename if exists or timestamp (YYYY/MM/DD HH:MM)
func get_formated_file_name() -> String:
	if file_name.is_empty():
		var timestamp : Array = [date_created.year, date_created.month , date_created.day, date_created.hour, date_created.minute]
		return "%04d/%02d/%02d %02d:%02d"%timestamp
	return file_name
