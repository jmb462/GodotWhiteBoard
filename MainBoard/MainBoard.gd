extends Control

var boards_array : Array[Board] = []
var board : Board = null
var current_board : int = -1

@onready var boards : Control = $VBox/Boards

@onready var packed_board : PackedScene = preload("res://Board/Board.tscn")

func _ready() -> void:
	if not is_instance_valid(board):
		add_board(current_board)
	get_tree().get_root().connect("files_dropped", _on_drop)

func _on_drop(data):
	var image : Image = Image.new()
	image.load(data[0])
	board.create_image_widget(image)

#
#	Free draw button has been pressed
#
func _on_pen_pressed() -> void:
	board.set_mode(G.BOARD_MODE.PEN)

func _on_palette_text_pressed() -> void:
	board.set_mode(G.BOARD_MODE.TEXT_POSITION)

func _on_palette_image_pressed():
	board.set_mode(G.BOARD_MODE.IMAGE_POSITION)

func _on_palette_pointer_pressed():
	board.set_mode(G.BOARD_MODE.NONE)



func _on_palette_paste_pressed():
	if DisplayServer.clipboard_has_image():
		board.set_mode(G.BOARD_MODE.PASTE_IMAGE)
		board.create_image_widget(DisplayServer.clipboard_get_image())
	elif DisplayServer.clipboard_has():
		board.set_mode(G.BOARD_MODE.PASTE_TEXT)
		var text_widget = board.create_text_widget()
		text_widget.set_text(DisplayServer.clipboard_get())
		text_widget.position = (board.size - text_widget.size) / 2.0
		text_widget.synchronize()

func add_board(p_index : int):
	if is_instance_valid(board):
		board.unfocus()
	var new_board : Board = packed_board.instantiate()	
	boards.add_child(new_board)
	if is_instance_valid(board):
		board.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		board.hide()
	board = new_board
	if p_index < 0:
		boards_array.append(new_board)
	else:
		boards_array.insert(p_index + 1, new_board)
	current_board = p_index + 1
	
	var vt : ViewportTexture = ViewportTexture.new()
	vt = board.viewport.get_texture()
	
	await get_tree().process_frame
	
	var i = $BoardsPreview/ScrollContainer/ItemList.add_icon_item(vt)
	$BoardsPreview/ScrollContainer/ItemList.move_item(i, current_board)
	$BoardsPreview/ScrollContainer/ItemList.select(current_board)
	$BoardsPreview/ScrollContainer/ItemList.icon_scale = 180 / vt.get_size().x
	
	
	
	
	
func _on_new_board_pressed():
	add_board(current_board)

func _on_previous_board_pressed():
	if current_board > 0:
		board.unfocus()
		board.hide()
		current_board -= 1
		board = boards_array[current_board]
		board.show()
		$BoardsPreview/ScrollContainer/ItemList.select(current_board)
		
func _on_next_board_pressed():
	if current_board < boards_array.size() - 1:
		board.unfocus()
		board.hide()
		current_board += 1
		board = boards_array[current_board]
		board.show()
		$BoardsPreview/ScrollContainer/ItemList.select(current_board)


func _on_clear_board_pressed():
	print("delete board")


func _on_palette_freeze_pressed():
	var rect : Rect2 = board.get_whiteboard_board()
	var img : Image = get_viewport().get_texture().get_image()
	img.blit_rect(img,rect, Vector2.ZERO)
	img.crop(int(rect.size.x), int(rect.size.y))
	var aspect_ratio : float = rect.size.x / rect.size.y
	img.resize(150, int(150 / aspect_ratio) )
	
	var tex = ImageTexture.create_from_image(img)
	$BoardsPreview/VBox/preview.texture = tex


func _on_item_list_item_selected(p_index :int ) -> void:
	if p_index < boards_array.size():
		board.unfocus()
		board.hide()
		current_board = p_index
		board = boards_array[p_index]
		board.show()
