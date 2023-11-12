extends Control
class_name DocumentManager

signal document_requested(document : Document, board_uid : int)

@onready var document_tree : DocumentTree = $HBox/DocumentTree
@onready var board_list : ItemList = $HBox/ThumbnailsContainer/BoardList

var boards_dict : Dictionary = {}
var current_document : Document = null

func activate(p_document_uid : int, p_board_uid : int, p_rename : bool = false) -> void:
	show()
	document_tree.rebuild_tree()
	document_tree.select_document(p_document_uid)
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
	print("delete document requested")
	if document_tree.is_document():
		if is_instance_valid(current_document):
			delete_document(current_document)
	else:
		var folder_array : Array[String] = []
		var file_array : Array[String] = []
		get_file_and_folders(document_tree.get_selected().get_meta("path"), folder_array, file_array)
		delete_folder(folder_array, file_array)
		
	document_tree.rebuild_tree()
	board_list.clear()
	document_tree.set_item_selected(0)

func _on_main_menu_duplicate_document_requested() -> void:
	print("duplicate document requested")

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
		
		
func delete_folder(p_folder_array : Array[String], p_file_array : Array[String]) -> void:
	for file : String in p_file_array:
		DirAccess.remove_absolute(file)
	while p_folder_array.size() > 0:
		DirAccess.remove_absolute(p_folder_array.pop_back())
	
func delete_document(p_document : Document) -> void:
	if not is_instance_valid(document_tree.get_selected()):
		return
	var selected_index : int = document_tree.get_selected().get_index()
	var path : String = p_document.get_document_path()
	var dir : DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while file_name != "":
			dir.remove(path + '/' + file_name)
			file_name = dir.get_next()
	dir.remove(path)
	document_tree.rebuild_tree()
	board_list.clear()
	document_tree.set_item_selected(selected_index)


func _on_main_menu_new_folder_requested() -> void:
	var path : String = G.ROOT_DOCUMENT_FOLDER
	var dir : DirAccess = DirAccess.open(path)
	var folder_number : int = 1
	var folder_name : String = "New folder"
	
	while (DirAccess.dir_exists_absolute(path + '/' + folder_name)):
		folder_number += 1
		folder_name = "New folder (%s)" % folder_number

	
	var error : Error = dir.make_dir_recursive(folder_name)
	print(error)
	document_tree.rebuild_tree()
