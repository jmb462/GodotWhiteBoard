extends Tree
class_name DocumentTree

signal document_selected(document : Document)
signal folder_selected()

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
				if DirAccess.get_files_at(new_path).find(G.DOCUMENT_FILE_NAME) == -1:
					var dir_item : TreeItem = create_new_item(parent_item, file_name, folder_icon, new_path)
					dir_contents(new_path, dir_item)
				else:
					var doc_path : String = "%s/%s" % [new_path, G.DOCUMENT_FILE_NAME]
					document = load(doc_path)
					var doc_item : TreeItem = create_new_item(parent_item, document.get_formated_file_name(), document_icon, new_path)
					document_items.append(doc_item)
					doc_item.set_meta("file_name", document.get_formated_file_name())
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
	else:
		emit_signal("folder_selected")


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
	if old_path != new_path:
		DirAccess.rename_absolute(old_path, new_path)
		rebuild_tree()

func rename_document(p_item : TreeItem) -> void:
	var new_name : String = p_item.get_text(0)
	if not new_name.is_valid_filename():
		p_item.set_text(0, old_item_text)
		p_item.set_editable(0, false)
	var item_document_path : String = p_item.get_meta("doc_path", "")
	var item_document : Document = load(item_document_path)
	if is_instance_valid(item_document):
		item_document.file_name = new_name
		ResourceSaver.save(item_document, item_document_path)
		rebuild_tree()

func _on_item_edited() -> void:
	if is_document():
		rename_document(get_selected())
	else:
		rename_folder(get_selected())


func select_document(p_document_uid : int) -> void:
	for item : TreeItem in document_items:
		if item.get_meta("uid") == p_document_uid:
			set_selected(item, 0)
			

func set_item_selected(p_index : int) -> void:
	if p_index >= document_items.size():
		p_index = document_items.size() - 1
	if p_index < 0:
		deselect_all() 
	else:
		set_selected(document_items[p_index], 0)

func _get_drag_data(p_position):
	var item = get_item_at_position(p_position)
	if not is_instance_valid(item):
		return ""
	var hbox : HBoxContainer = HBoxContainer.new()
	var icon : TextureRect = TextureRect.new()
	icon.set_texture(item.get_icon(0))
	var label : Label = Label.new()
	hbox.add_child(icon)
	hbox.add_child(label)
	
	label.text = item.get_text(0)
	set_drag_preview(hbox)
	return get_item_at_position(p_position)
	
func _can_drop_data(p_position, source):
	var target : TreeItem =  get_item_at_position(p_position)
	if not is_instance_valid(source) or not is_instance_valid(target):
		return false	
	if is_document(target):
		drop_mode_flags = DROP_MODE_INBETWEEN
		return true
	drop_mode_flags = DROP_MODE_ON_ITEM
	return true

func _drop_data(p_position : Vector2, source : Variant) -> void:
	var target : TreeItem =  get_item_at_position(p_position)
	if not is_instance_valid(target):
		return
	if is_document(source):
		move_document_to_folder(source.get_meta("doc_path").get_base_dir(), get_item_base_directory(target))
	else:
		move_folder_to_folder(get_item_base_directory(source),  get_item_base_directory(target))

## Returns the root folder of a TreeItem.
## Returns the entire path for folder items and returns the upper folder for document folder
func get_item_base_directory(p_item : TreeItem) -> String:
	if not is_document(p_item):
		return p_item.get_meta("path")
	var document_base_folder = p_item.get_meta("doc_path").get_base_dir()
	var i : int = 0
	var result : int = -2
	var last_slash : int = -1
	while result != -1:
		result =  document_base_folder.find('/', i)
		if result != -1:
			last_slash = result
		i += 1
	return document_base_folder.left(last_slash)

func move_document_to_folder(p_source_path : String, p_dest_path : String) -> void:
	print("move %s to %s "%[p_source_path, p_dest_path + '/' + p_source_path.get_file()])
	DirAccess.rename_absolute(p_source_path, p_dest_path + '/' + p_source_path.get_file() )
	rebuild_tree()
	
func move_folder_to_folder(p_source_path : String, p_dest_path  : String) -> void:
	print("source ", p_source_path)
	var dir_name : String = p_source_path.get_slice("/", p_source_path.get_slice_count("/") - 1)
	var new_path : String = p_dest_path + '/' + dir_name
	print("source base ", dir_name)
	print("dest ", new_path)
	DirAccess.rename_absolute(p_source_path, new_path)
	rebuild_tree()
