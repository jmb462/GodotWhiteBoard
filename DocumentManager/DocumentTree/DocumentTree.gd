extends Tree
class_name DocumentTree

signal document_selected(document : Document)

var folder_path : String = "user://documents"

var document : Document = null

var document_items : Array[TreeItem] = []

## Item text before being modified by double click
var old_item_text : String = ""

@onready var folder_icon : Texture2D = preload("res://Assets/Buttons/file-manager-icon.png")
@onready var document_icon : Texture2D = preload("res://Assets/Buttons/preview_toggle.png")

func _ready() -> void:
	rebuild_tree()

func dir_contents(path : String, parent_item : TreeItem) -> void:
	var dir : DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var new_path : String = path + '/' + file_name
				if DirAccess.get_files_at(new_path).find("document.tres") == -1:
					var dir_item : TreeItem = create_new_item(parent_item, file_name, folder_icon, new_path)
					dir_contents(new_path, dir_item)
				else:
					var doc_path : String = new_path + "/document.tres"
					document = load(doc_path)
					var doc_item : TreeItem = create_new_item(parent_item, document.get_formated_file_name(), document_icon, new_path)
					document_items.append(doc_item)
					doc_item.set_meta("doc_path", doc_path)
					doc_item.set_meta("uid", document.uid)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func rebuild_tree() -> void:
	clear()
	document_items.clear()
	var root_item : TreeItem = create_item()
	root_item.set_text(0, "Documents")
	dir_contents(folder_path, root_item)

func create_new_item(p_parent : TreeItem, p_text : String, p_icon : Texture2D, p_path : String) -> TreeItem:
	var item : TreeItem = create_item(p_parent)
	item.set_text(0, p_text)
	item.set_icon(0, p_icon)
	item.set_icon_max_width(0,16)
	item.set_meta("path", p_path)
	return item

func get_document(p_item : TreeItem) -> Document:
	if not is_document(p_item):
		return null
	return load(p_item.get_meta("doc_path", null))

func get_item_path(p_item : TreeItem = get_selected()) -> String:
	return p_item.get_meta("path", "")

func is_document(p_item : TreeItem = get_selected()) -> bool:
	return p_item.has_meta("doc_path")


func _on_item_selected() -> void:
	if is_document(get_selected()):
		emit_signal("document_selected", get_document(get_selected()))




func _on_gui_input(p_event : InputEvent) -> void:
	if p_event is InputEventMouseButton:
		if p_event.is_pressed():
			if is_instance_valid(get_selected()):
				old_item_text =  get_selected().get_text(0)
				get_selected().set_editable(0, p_event.is_double_click())

func rename_folder(item : TreeItem) -> void:
	var new_name : String = item.get_text(0)
	var old_path : String = item.get_meta("path")
	if not new_name.is_valid_filename():
		item.set_text(0, old_item_text)
		item.set_editable(0, false)
	var new_path : String = old_path.get_base_dir()+'/'+new_name
	DirAccess.rename_absolute(old_path, new_path)
	rebuild_tree()
	

func _on_item_edited() -> void:
	if not is_document():
		rename_folder(get_selected())

func select_document(p_document_uid : int) -> void:
	for item : TreeItem in document_items:
		if item.get_meta("uid") == p_document_uid:
			set_selected(item, 0)
			
