extends Control
class_name DocumentManager

signal document_requested(document : Document, board_uid : int)

@onready var document_tree : DocumentTree = $HBox/DocumentTree
@onready var board_list : ItemList = $HBox/ThumbnailsContainer/BoardList

var boards_dict : Dictionary = {}
var current_document : Document = null

func activate(p_document_uid : int, p_board_uid : int) -> void:
	show()
	document_tree.rebuild_tree()
	document_tree.select_document(p_document_uid)
	print('print need to preselect board : ', p_board_uid)
	var current_page : String = str(p_board_uid)
	if boards_dict.has(current_page):
		board_list.select(boards_dict.get(str(p_board_uid)))
	
func show_thumbnails(p_document : Document) -> void:
	current_document = p_document
	if p_document == null:
		return
	board_list.clear()
	print(" ======= ")
	print("boards : ", p_document.boards.size())
	for board_data : BoardData in p_document.boards:
		var thumbnail_path : String = p_document.get_document_path() + '/' + str(board_data.uid) + '_thumbnail.jpg'
		if FileAccess.file_exists(thumbnail_path):
			var image : Image = Image.load_from_file(thumbnail_path)
			var index : int = board_list.add_icon_item(ImageTexture.create_from_image(image))
			boards_dict[str(board_data.uid)] = index
			boards_dict[str(index)] = board_data.uid


func _on_board_list_item_activated(index):
	var selected_index : int = board_list.get_selected_items()[0]
	var board_uid = boards_dict.get(str(selected_index))
	emit_signal("document_requested", current_document, selected_index)
