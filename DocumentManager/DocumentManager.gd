extends Control
class_name DocumentManager

signal document_requested(document : Document, board_uid : int)

@onready var document_tree : DocumentTree = $HBox/VBox/DocumentTree
@onready var board_list : ItemList = $HBox/ThumbnailsContainer/BoardList

var boards_dict : Dictionary = {}
var current_document : Document = null

## Switch to DocumentManager and select the current edited document in Tree.
func activate(p_document_uid : int, p_board_uid : int, p_rename : bool = false) -> void:
	show()
	document_tree.rebuild_tree()
	document_tree.select_item_by_document_uid(p_document_uid)
	var current_page : String = str(p_board_uid)
	if boards_dict.has(current_page):
		board_list.select(boards_dict.get(str(p_board_uid)))
	if p_rename:
		await get_tree().process_frame
		document_tree.edit_selected(true)

func _on_document_tree_folder_selected() -> void:
	board_list.clear()

func show_thumbnails(p_document : Document) -> void:
	current_document = p_document
	if p_document == null:
		return
	board_list.clear()
	for board_data : BoardData in p_document.boards:
		var thumbnail_path : String = p_document.get_document_path() + '/' + str(board_data.uid) + '_thumbnail.jpg'
		if FileAccess.file_exists(thumbnail_path):
			var image : Image = Image.load_from_file(thumbnail_path)
			var index : int = board_list.add_icon_item(ImageTexture.create_from_image(image))
			boards_dict[str(board_data.uid)] = index
			boards_dict[str(index)] = board_data.uid


func _on_board_list_item_activated(p_index : int) -> void:
	emit_signal("document_requested", current_document, p_index)


func _on_main_menu_delete_document_requested() -> void:
	if document_tree.is_document():
		if is_instance_valid(current_document):
			delete_selected_item_document(current_document)
	else:
		var folder_array : Array[String] = []
		var file_array : Array[String] = []
		get_file_and_folders(document_tree.get_item_path(), folder_array, file_array)
		delete_folder(folder_array, file_array)
		
	document_tree.rebuild_tree()
	board_list.clear()
	document_tree.set_item_selected(0)

func _on_main_menu_duplicate_document_requested() -> void:
	var item : TreeItem = document_tree.get_selected()
	if not is_instance_valid(item) or not document_tree.is_document(item):
		return
	if item.get_parent() == null:
		return
	var new_uid : int = ResourceUID.create_id()
	var source_document : Document = document_tree.get_document(item)
	var old_path : String = source_document.get_document_path()
	var new_path : String =  source_document.get_document_path().get_base_dir() + '/' + str(new_uid)
	var new_document_path : String = new_path + '/' + G.DOCUMENT_FILE_NAME
	DirAccess.make_dir_recursive_absolute(new_path)
	copy_folder_content(old_path, new_path)
	var new_document : Document = load(new_document_path)
	new_document.set_uid(new_uid)
	new_document.set_file_name(get_copy_file_name(source_document.get_formated_file_name()))
	ResourceSaver.save(new_document, new_document_path)
	document_tree.rebuild_tree()
	document_tree.select_document(new_uid)
	await get_tree().process_frame
	document_tree.edit_selected(true)

func copy_folder_content(p_source_folder : String, p_dest_folder : String) -> void:
	var dir : DirAccess = DirAccess.open(p_source_folder)
	if dir:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while not file_name.is_empty():
			dir.copy(p_source_folder+'/'+file_name, p_dest_folder+'/'+file_name)
			file_name = dir.get_next()

## Returns the copy name with copy suffix and number if needed
func get_copy_file_name(p_name : String) -> String:
	if p_name.contains(G.COPIED_SUFFIX):
		var regex : RegEx = RegEx.new()
		regex.compile('- Copy( \\((\\d+)\\))?$')
		var result : RegExMatch = regex.search(p_name)
		var old_suffix : String = result.get_string()
		
		regex.compile('\\d+')
		result = regex.search(old_suffix)
		var number : int = 1
		if result != null:
			number = int(result.get_string()) + 1
		
		p_name = p_name.trim_suffix(old_suffix) + G.COPIED_SUFFIX + ' (%s)' % number
		return p_name
	return p_name + G.COPIED_SUFFIX

## Populates given folder and files array with given directory content
func get_file_and_folders(p_dir_path : String, folder_array : Array[String], file_array : Array[String]) -> void:
	folder_array.append(p_dir_path)
	var dir : DirAccess = DirAccess.open(p_dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir():
				var sub_dir : String = p_dir_path + '/' + file_name
				get_file_and_folders(sub_dir, folder_array, file_array)
			else:
				file_array.append(p_dir_path + '/' + file_name)
			file_name = dir.get_next()
		
## Delete folder and contents
func delete_folder(p_folder_array : Array[String], p_file_array : Array[String]) -> void:
	for file : String in p_file_array:
		DirAccess.remove_absolute(file)
	while p_folder_array.size() > 0:
		DirAccess.remove_absolute(p_folder_array.pop_back())

## Delete document
func delete_selected_item_document(p_document : Document) -> void:
	if not is_instance_valid(document_tree.get_selected()):
		return
	if not is_instance_valid(p_document):
		return
	var selected_index : int = document_tree.get_selected().get_index()
	erase_document_files(p_document)
	document_tree.rebuild_tree()
	board_list.clear()
	document_tree.set_item_selected(selected_index)

## Erase document files
func erase_document_files(p_document : Document) -> void:
	if not is_instance_valid(p_document):
		return
	var path : String = p_document.get_document_path()
	var dir : DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while file_name != "":
			dir.remove(path + '/' + file_name)
			file_name = dir.get_next()
	dir.remove(path)

func _on_main_menu_new_folder_requested() -> void:
	var path : String = G.ROOT_DOCUMENT_FOLDER
	
	var selected_item : TreeItem = document_tree.get_selected()
	if is_instance_valid(selected_item):
		path = document_tree.get_item_root_path(selected_item)
		print("base dir", path)
	
	var dir : DirAccess = DirAccess.open(path)
	var folder_number : int = 1
	var folder_name : String = "New folder"
	
	while (DirAccess.dir_exists_absolute(path + '/' + folder_name)):
		folder_number += 1
		folder_name = "New folder (%s)" % folder_number

	var _error : Error = dir.make_dir_recursive(folder_name)
	document_tree.rebuild_tree()
