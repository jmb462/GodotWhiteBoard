extends Control

var boards_array : Array[Board] = []
var board : Board = null
var current_board : int = -1

# Index of the board when delete board is requested
var delete_index : int = -1

@onready var boards : Control = $VBox/HBox/Boards
@onready var preview_list : AnimatedList = $VBox/HBox/PreviewList
@onready var main_menu : Panel = $VBox/MainMenu

@onready var delete_confirmation_dialog : ConfirmationDialog = $DeleteConfirmationDialog
@onready var clear_confirmation_dialog : ConfirmationDialog = $ClearConfirmationDialog

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


func add_board(p_index : int) -> Board:
	if is_instance_valid(board):
		board.unfocus()
	var new_board = packed_board.instantiate()
	boards.add_child(new_board)
	if is_instance_valid(board):
		board.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		board.hide()
	board = new_board
	boards_array.insert(p_index + 1, new_board)
	current_board = p_index + 1
	
	await get_tree().process_frame
	
	var preview_texture : ViewportTexture = board.viewport.get_texture()
	
	var scale_factor : float = float(preview_list.item_max_size_horizontal) / float(preview_texture.get_size().x)
	
	preview_list.preview_scale = scale_factor
	var preview_item = preview_list.create_item(p_index + 1, preview_texture)
	preview_list.select(preview_item.index)
	
	clear_display()
	set_scroll_container_size()
	set_boards_size()
	
	return board


func _on_new_board_pressed():
	add_board(current_board)


func _on_previous_board_pressed():
	change_board(current_board - 1)
	
	
func _on_next_board_pressed():
	change_board(current_board + 1)


func change_board(p_index : int, delayed : bool = true) -> void:
	if p_index < 0:
		return
	board.set_mode(G.BOARD_MODE.NONE)
	board.unfocus()
	clear_display()
	current_board = p_index
	
	if current_board >= boards_array.size():
		current_board = boards_array.size() - 1
	
	board = boards_array[current_board]
	board.unfocus()
	board.set_mode(G.BOARD_MODE.NONE)
	synchronize_display()
	if delayed:
		await get_tree().create_timer(0.1).timeout
	show_only_current_board()
	
	preview_list.select(current_board)

func show_only_current_board():
	for i in boards_array.size():
		boards_array[i].visible = i == current_board
		

func clear_board_confirm():
	clear_confirmation_dialog.popup_centered()

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

func _on_boards_resized():
	if is_instance_valid(boards):
		for each_board in boards.get_children():
			each_board.custom_minimum_size = board.size

func set_boards_size() -> void:
	boards.size = Display.size
	var display_aspect_ratio = float(Display.size.x)/float(Display.size.y)
	var available_height = size.y -main_menu.size.y - 40
	var preview_width = preview_list.size.x if preview_list.visible else 0.0
	var available_width = size.x - preview_width - 40
	var board_aspect_ratio = available_width / available_height

	
	if board_aspect_ratio > display_aspect_ratio:
		boards.scale = Vector2.ONE * (available_height / float(Display.size.y))
	else:
		boards.scale = Vector2.ONE * (available_width / float(Display.size.x))
	
	boards.position.x = (size.x - boards.size.x * boards.scale.x - preview_width) / 2.0

func set_scroll_container_size() -> void:
	preview_list.size.y = get_viewport_rect().size.y - preview_list.global_position.y
	preview_list.position.x = size.x - preview_list.size.x
	
func _on_resized():
	if is_node_ready():
		set_scroll_container_size()
		set_boards_size()

#
# Delete all clones from display board
#
func clear_display() -> void:
	var displayed_widgets : Array = Display.presentation_screen.get_children()
	if not displayed_widgets.is_empty():
		var tween = create_tween()
		for widget in displayed_widgets:
			tween.set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(widget, "modulate:a", 0.0, 0.2)
		await tween.finished
		for widget in displayed_widgets:
			if is_instance_valid(widget):
				if is_instance_valid(widget.master):
					widget.master.clone = null
				widget.queue_free()

#
# Clone each widget of board on display screen
#
func synchronize_display() -> void:
	for widget in board.get_widgets():
		board.clone_widget(widget)


#
# Duplicate board and all widgets on a new board
#
func duplicate_board(p_index : int) -> void:
	print("duplicate_board ",p_index)
	var new_board = packed_board.instantiate()
	var duplicated_board = boards_array[p_index]
	duplicated_board.unfocus()
	boards.add_child(new_board)
	boards.move_child(new_board, 0)
	for widget in duplicated_board.get_widgets():
		duplicated_board.copy_widget_to_board(widget, new_board)

	boards_array.insert(p_index + 1, new_board)

	await get_tree().process_frame
	preview_list.create_item(p_index + 1, boards_array[p_index + 1].viewport.get_texture())
	change_board(p_index + 1)

#
# Show a confirmation dialog when board deletion is requested
#
func delete_confirm(p_index : int) -> void:
	# Cannot delete last board
	if boards_array.size() <= 1:
		return
	delete_confirmation_dialog.popup_centered()
	delete_confirmation_dialog.dialog_text = "Are you sure you want to delete page %s?" % str(p_index + 1)
	delete_index = p_index

#
# Delete board at p_index
#
func delete_board(p_index : int = delete_index) -> void:
	if p_index < 0:
		return
	var offset : int = -1 if  p_index < current_board else 0
		
	var removed_board = boards_array[p_index]
	boards_array.remove_at(p_index)
	
	removed_board.queue_free()
	if current_board + offset == p_index:
		change_board(current_board + offset)
	
	preview_list.delete_item(p_index)
	preview_list.select(current_board)


func _on_preview_list_item_moved(from_index : int , to_index : int):

	if from_index < to_index:
		boards_array.insert(to_index + 1, boards_array[from_index])
		boards_array.remove_at(from_index)
	else:
		boards_array.insert(to_index, boards_array[from_index])
		boards_array.remove_at(from_index + 1)

	change_board(to_index)



