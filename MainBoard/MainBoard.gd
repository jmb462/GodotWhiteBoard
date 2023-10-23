extends Control

var boards_array : Array[Board] = []
var board : Board = null
var current_board : int = -1

@onready var boards : Control = $VBox/HBox/Boards
@onready var scroll_container : ScrollContainer = $VBox/HBox/ScrollContainer
@onready var preview_list : ItemList = $VBox/HBox/ScrollContainer/PreviewList
@onready var main_menu : Panel = $VBox/MainMenu

@onready var packed_board : PackedScene = preload("res://Board/Board.tscn")

func _ready() -> void:
	if not is_instance_valid(board):
		add_board(current_board)
	get_tree().get_root().connect("files_dropped", _on_drop)
	_on_resized()

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
	
	var i = preview_list.add_icon_item(vt)
	preview_list.move_item(i, current_board)
	preview_list.select(current_board)
	preview_list.icon_scale = 180 / vt.get_size().x
	
	clear_display()
	set_scroll_container_size()
	set_boards_size()

func _on_new_board_pressed():
	add_board(current_board)

func _on_previous_board_pressed():
	if current_board > 0:
		board.unfocus()
		board.hide()
		clear_display()
		current_board -= 1
		board = boards_array[current_board]
		board.show()
		synchronize_display()
		preview_list.select(current_board)
		
func _on_next_board_pressed():
	if current_board < boards_array.size() - 1:
		board.unfocus()
		board.hide()
		clear_display()
		current_board += 1
		board = boards_array[current_board]
		board.show()
		synchronize_display()
		preview_list.select(current_board)


func _on_clear_board_pressed():
	for widget in board.get_widgets():
		widget.delete()

func _on_palette_freeze_pressed():
	pass
	#var rect : Rect2 = board.get_whiteboard_board()
	#var img : Image = get_viewport().get_texture().get_image()
	#img.blit_rect(img,rect, Vector2.ZERO)
	#img.crop(int(rect.size.x), int(rect.size.y))
	#var aspect_ratio : float = rect.size.x / rect.size.y
	#img.resize(150, int(150 / aspect_ratio) )
	#
	#var tex = ImageTexture.create_from_image(img)
	#$BoardsPreview/VBox/preview.texture = tex


func _on_item_list_item_selected(p_index :int ) -> void:
	if p_index < boards_array.size():
		board.unfocus()
		board.hide()
		clear_display()
		current_board = p_index
		board = boards_array[p_index]
		board.show()
		synchronize_display()


func _on_boards_resized():
	if is_instance_valid(boards):
		for each_board in boards.get_children():
			each_board.viewport.size = board.size

func set_boards_size() -> void:
	boards.size = Display.size
	var display_aspect_ratio = float(Display.size.x)/float(Display.size.y)
	var available_height = size.y -main_menu.size.y - 40
	var sc_width = scroll_container.size.x if scroll_container.visible else 0.0
	var available_width = size.x - sc_width - 40
	var board_aspect_ratio = available_width / available_height

	
	if board_aspect_ratio > display_aspect_ratio:
		boards.scale = Vector2.ONE * (available_height / float(Display.size.y))
	else:
		boards.scale = Vector2.ONE * (available_width / float(Display.size.x))
	
	boards.position.x = (size.x - boards.size.x * boards.scale.x - sc_width) / 2.0

func set_scroll_container_size() -> void:
	scroll_container.size.y = size.y - main_menu.size.y
	scroll_container.position.x = size.x - scroll_container.size.x
	
func _on_resized():
	if is_node_ready():
		set_scroll_container_size()
		set_boards_size()

func clear_display() -> void:
	for widget in Display.presentation_screen.get_children():
		widget.master.clone = null
		widget.queue_free()

func synchronize_display() -> void:
	for widget in board.get_widgets():
		board.clone_widget(widget)
