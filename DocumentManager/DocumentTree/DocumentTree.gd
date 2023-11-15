extends Tree
class_name DocumentTree

signal document_selected(document : Document)
signal folder_selected()

var document : Document = null

var document_items : Array[TreeItem] = []
var custom_tree_items : Array[CustomTreeItem] = []

## Item text before being modified by double click
var old_item_text : String = ""


@onready var folder_icon : Texture2D = preload("res://Assets/Buttons/file-manager-icon.png")
@onready var document_icon : Texture2D = preload("res://Assets/Buttons/preview_toggle.png")

func _ready() -> void:
	rebuild_tree()

## Scan dir to create the Tree.
func dir_contents(path : String, p_parent_custom_item : CustomTreeItem) -> void:
	var dir : DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var new_path : String = path + '/' + file_name
				if DirAccess.get_files_at(new_path).find(G.DOCUMENT_FILE_NAME) == -1:
					#var dir_item : TreeItem = create_new_item(parent_item, file_name, folder_icon, new_path)
					
					var custom_tree_item : CustomTreeItem = create_custom_tree_item()
					custom_tree_item.root_path = new_path
					custom_tree_item.item_path = new_path
					custom_tree_item.file_name = file_name
					custom_tree_item.type = CustomTreeItem.TYPE.FOLDER
					p_parent_custom_item.child_items.append(custom_tree_item)

					dir_contents(new_path, custom_tree_item)
				else:
					var document_full_path : String = "%s/%s" % [new_path, G.DOCUMENT_FILE_NAME]
					document = load(document_full_path)
					
					var custom_tree_item : CustomTreeItem = create_custom_tree_item()
					custom_tree_item.root_path = new_path.get_base_dir()
					custom_tree_item.item_path = new_path
					custom_tree_item.document_full_path = document_full_path
					custom_tree_item.file_name = document.get_formated_file_name()
					custom_tree_item.type = CustomTreeItem.TYPE.DOCUMENT
					custom_tree_item.document_uid = document.get_uid()
					custom_tree_item.date_created = document.document_info.date_created
					custom_tree_item.last_modified = document.document_info.last_modified
					p_parent_custom_item.child_items.append(custom_tree_item)
					
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")


func create_custom_tree_item() -> CustomTreeItem:
	var custom_tree_item : CustomTreeItem = CustomTreeItem.new()
	custom_tree_items.append(custom_tree_item)
	return custom_tree_item
	
## Rebuild the whole tree.
func rebuild_tree() -> void:
	clear()
	custom_tree_items.clear()
	
	var root_custom_item : CustomTreeItem = create_custom_tree_item()
	root_custom_item.type = CustomTreeItem.TYPE.FOLDER
	root_custom_item.file_name = "Documents"
	root_custom_item.root_path = G.ROOT_DOCUMENT_FOLDER
	root_custom_item.item_path = G.ROOT_DOCUMENT_FOLDER
	root_custom_item.selectable = false
	root_custom_item.editable = false
	
	var root_item : TreeItem = create_item()
	root_custom_item.tree_item = root_item
	root_item.set_meta("custom_tree_item",  root_custom_item)
	root_item.set_text(0, "Documents")
	root_item.set_icon(0, folder_icon)
	root_item.set_icon_max_width(0,16)
	root_item.set_editable(0, false)
	root_item.set_selectable(0, false)
	dir_contents(G.ROOT_DOCUMENT_FOLDER, root_custom_item)
	create_tree_items_from_custom_tree_items(root_custom_item, root_item)

func create_tree_items_from_custom_tree_items(p_custom_tree_item : CustomTreeItem, p_root_item : TreeItem) -> void:
	for custom_tree_item : CustomTreeItem in p_custom_tree_item.child_items:
		var item : TreeItem = create_item(p_root_item)
		# Set mutual references between TreeItem and CustomTreeItem
		custom_tree_item.tree_item = item
		item.set_meta("custom_tree_item",  custom_tree_item)
		
		item.set_text(0, custom_tree_item.file_name + '(%s)'%custom_tree_items.find(custom_tree_item))
		item.set_icon(0, folder_icon if custom_tree_item.is_folder() else document_icon)
		item.set_icon_max_width(0,16)
		if custom_tree_item.is_folder():
			create_tree_items_from_custom_tree_items(custom_tree_item, item)

## Return Document resource from TreeItem.
func get_document(p_item : TreeItem) -> Document:
	if not is_document(p_item):
		return null
	return load(get_custom_tree_item(p_item).document_full_path)


## Returns the path of the folder or document linked to the item.
func get_item_path(p_item : TreeItem = get_selected()) -> String:
	if not is_instance_valid(p_item):
		return ""
	return get_custom_tree_item(p_item).item_path

## Returns the root path of the folder or document linked to the item.
func get_item_root_path(p_item : TreeItem = get_selected()) -> String:
	if not is_instance_valid(p_item):
		return ""
	return get_custom_tree_item(p_item).root_path


## Return if TreeItem is a Document (not a folder).
func is_document(p_item : TreeItem = get_selected()) -> bool:
	if not is_instance_valid(p_item) or not is_instance_valid(get_custom_tree_item(p_item)):
		return false
	return get_custom_tree_item(p_item).is_document()

## TreeItem has been selected.
func _on_item_selected() -> void:
	print("%s %s"%[get_custom_selected_item().file_name, get_custom_selected_item().root_path]) ## TODO : synch both indexes
	if is_document(get_selected()):
		emit_signal("document_selected", get_document(get_selected()))
	else:
		emit_signal("folder_selected")

func get_custom_tree_item(p_item : TreeItem) -> CustomTreeItem:
	if not is_instance_valid(p_item):
		return null
	return p_item.get_meta("custom_tree_item", null)

func get_custom_selected_item() -> CustomTreeItem:
	if not is_instance_valid(get_selected()):
		return null
	return get_custom_tree_item(get_selected())

## Event occurs on DocumentTree
func _on_gui_input(p_event : InputEvent) -> void:
	if p_event is InputEventMouseButton:
		if p_event.is_pressed():
			if is_instance_valid(get_selected()):
				old_item_text =  get_selected().get_text(0)
				get_selected().set_editable(0, p_event.is_double_click())

## Rename folder.
func rename_folder(item : TreeItem) -> void:
	var new_name : String = item.get_text(0)
	var old_path : String = get_custom_tree_item(item).root_path
	if not new_name.is_valid_filename():
		item.set_text(0, old_item_text)
		item.set_editable(0, false)
	var new_path : String = old_path.get_base_dir()+'/'+new_name
	if old_path != new_path:
		DirAccess.rename_absolute(old_path, new_path)
		rebuild_tree()

## Rename document.
func rename_document(p_item : TreeItem) -> void:
	var new_name : String = p_item.get_text(0)
	if not new_name.is_valid_filename():
		p_item.set_text(0, old_item_text)
		p_item.set_editable(0, false)
	var item_document_path : String = get_item_doc_path(p_item)
	var item_document : Document = load(item_document_path)
	if is_instance_valid(item_document):
		item_document.set_file_name(new_name)
		ResourceSaver.save(item_document, item_document_path)
		rebuild_tree()
		select_item_by_document_uid(item_document.get_uid())

## Item is renamed.
func _on_item_edited() -> void:
	if is_document():
		rename_document(get_selected())
	else:
		rename_folder(get_selected())

## Select item by document unique ID.
func select_item_by_document_uid(p_document_uid : int) -> void:
	for custom_tree_item : CustomTreeItem in custom_tree_items:
		if custom_tree_item.document_uid == p_document_uid:
			set_selected(custom_tree_item.tree_item, 0)
			
## Select item by index.
func set_item_selected(p_index : int) -> void:
	if p_index >= custom_tree_items.size():
		p_index = custom_tree_items.size() - 1
	if p_index < 0:
		deselect_all() 
	else:
		print("trying to selec ", custom_tree_items[p_index].file_name )
		set_selected(custom_tree_items[p_index].tree_item, 0)

func get_item_uid(p_item : TreeItem) -> int:
	if not is_instance_valid(p_item):
		return -1
	return get_custom_tree_item(p_item).document_uid

func get_item_doc_path(p_item : TreeItem) -> String:
	if not is_instance_valid(p_item):
		return ""
	return get_custom_tree_item(p_item).document_full_path

## Begin drag'n'drop.
func _get_drag_data(p_position : Vector2) -> Variant:
	var item : TreeItem = get_item_at_position(p_position)
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

## Dragged TreeItem is over another item.
func _can_drop_data(p_position : Vector2, source : Variant) -> bool:
	var target : TreeItem =  get_item_at_position(p_position)
	if not is_instance_valid(source) or not is_instance_valid(target):
		return false	
	if is_document(target):
		drop_mode_flags = DROP_MODE_INBETWEEN
		return true
	drop_mode_flags = DROP_MODE_ON_ITEM
	return true

## TreeItem is dropped on Tree.
func _drop_data(p_position : Vector2, source : Variant) -> void:
	var target : TreeItem =  get_item_at_position(p_position)
	if not is_instance_valid(target):
		return
	if is_document(source):
		move_document_to_folder(get_custom_tree_item(source).document_full_path.get_base_dir(), get_custom_tree_item(target).root_path)
	else:
		move_folder_to_folder(get_custom_tree_item(source).root_path,  get_custom_tree_item(target).root_path)


 ## Moves a document to folder.
func move_document_to_folder(p_source_path : String, p_dest_path : String) -> void:
	DirAccess.rename_absolute(p_source_path, p_dest_path + '/' + p_source_path.get_file() )
	rebuild_tree()

## Moves a folder to a new folder.
func move_folder_to_folder(p_source_path : String, p_dest_path  : String) -> void:
	var dir_name : String = p_source_path.get_slice("/", p_source_path.get_slice_count("/") - 1)
	var new_path : String = p_dest_path + '/' + dir_name
	DirAccess.rename_absolute(p_source_path, new_path)
	rebuild_tree()
