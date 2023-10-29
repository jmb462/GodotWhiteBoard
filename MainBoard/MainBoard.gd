extends Control

## Emitted when board is created or deleted or when current board changed.
signal boards_changed(current_board : int, total_boards : int)

## Array of Board
var boards : Array[Board] = []

## Current board
var board : Board = null

## Curent board index
var current_board : int = -1

# Index of the board when delete board is requested
var delete_index : int = -1

@onready var boards_container : Control = $VBox/HBox/BoardsContainer
@onready var preview_list : AnimatedList = $VBox/HBox/PreviewList
@onready var main_menu : Panel = $VBox/MainMenu

@onready var delete_confirmation_dialog : ConfirmationDialog = $DeleteConfirmationDialog
@onready var clear_confirmation_dialog : ConfirmationDialog = $ClearConfirmationDialog
@onready var toggle_preview_panel : Panel = $TogglePreviewPanel

@onready var packed_board : PackedScene = preload("res://Board/Board.tscn")

func _ready() -> void:
	if not is_instance_valid(board):
		add_board(current_board)
	get_tree().get_root().connect("files_dropped", _on_drop)
	_on_resized()

func _on_drop(data : Variant) -> void:
	var image : Image = Image.new()
	image.load(data[0])
	board.create_image_widget(image)

#region Palett button callbacks
## Called when palett pen button is pressed
func _on_pen_pressed() -> void:
	board.set_mode(G.BOARD_MODE.PEN)

## Called when palett text button is pressed
func _on_palette_text_pressed() -> void:
	board.set_mode(G.BOARD_MODE.TEXT_POSITION)

## Called when palett image button is pressed
func _on_palette_image_pressed() -> void:
	board.set_mode(G.BOARD_MODE.IMAGE_POSITION)

## Called when palett arrow button is pressed
func _on_palette_pointer_pressed() -> void:
	board.set_mode(G.BOARD_MODE.NONE)

## Called when palett paste button is pressed
func _on_palette_paste_pressed() -> void:
	if DisplayServer.clipboard_has_image():
		board.set_mode(G.BOARD_MODE.PASTE_IMAGE)
		board.create_image_widget(DisplayServer.clipboard_get_image())
	elif DisplayServer.clipboard_has():
		board.set_mode(G.BOARD_MODE.PASTE_TEXT)
		var text_widget : TextWidget = board.create_text_widget()
		text_widget.set_text(DisplayServer.clipboard_get())
		text_widget.position = (board.size - text_widget.size) / 2.0
		text_widget.synchronize()
#endregion

func add_board(p_index : int) -> Board:
	if is_instance_valid(board):
		board.unfocus()
	var new_board : Board = packed_board.instantiate()
	board_signal_connect(new_board)
	boards_container.add_child(new_board)

	if is_instance_valid(board):
		board.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		board.hide()
		
	boards.insert(p_index + 1, new_board)
	
	current_board = p_index + 1
	
	set_board(new_board)
	
	await get_tree().process_frame
	
	var preview_texture : ViewportTexture = board.viewport.get_texture()
	
	var scale_factor : float = float(preview_list.item_max_size_horizontal) / float(preview_texture.get_size().x)
	
	preview_list.preview_scale = scale_factor
	var preview_item : AnimatedItem = preview_list.create_item(p_index + 1, preview_texture)
	preview_list.select(preview_item.index)
	
	clear_display()
	set_preview_list_size()
	set_boards_size()
	
	return board


func _on_new_board_pressed() -> void:
	add_board(current_board)


func _on_previous_board_pressed() -> void:
	change_board(current_board - 1)
	
	
func _on_next_board_pressed() -> void:
	change_board(current_board + 1)


func change_board(p_index : int, delayed : bool = true) -> void:
	if p_index < 0:
		return
	board.set_mode(G.BOARD_MODE.NONE)
	board.unfocus()
	clear_display()
	current_board = p_index
	
	if current_board >= boards.size():
		current_board = boards.size() - 1
	
	set_board(boards[current_board])
		
	synchronize_display()
	if delayed:
		await get_tree().create_timer(0.1).timeout
	
	show_only_current_board()
	
	preview_list.select(current_board)

func set_board(p_board : Board) -> void:
	board = p_board
	board.activate()
	emit_signal("boards_changed", current_board, boards.size())

func show_only_current_board() -> void:
	for i in boards.size():
		boards[i].visible = i == current_board

func clear_board_confirm() -> void:
	clear_confirmation_dialog.popup_centered()

func _on_clear_board_pressed() -> void:
	for widget in board.get_widgets():
		widget.delete()

func _on_palette_freeze_pressed() -> void:
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

func _on_boards_resized() -> void:
	if is_instance_valid(boards_container):
		for each_board in boards_container.get_children():
			each_board.custom_minimum_size = board.size

func set_boards_size() -> void:
	boards_container.size = Display.size
	var preview_width : float = 0.0
	if preview_list.visible:
		preview_width = preview_list.size.x
	boards_container.scale = Vector2.ONE * get_board_scale_factor(preview_width)
	boards_container.position.x = (size.x - boards_container.size.x * boards_container.scale.x - preview_width) / 2.0

func get_board_scale_factor(p_preview_width : float) -> float:
	var display_aspect_ratio : float = float(Display.size.x)/float(Display.size.y)
	
	var available_height : float = size.y - 20
	if main_menu.visible:
		available_height -= main_menu.size.y
		
	var available_width : float = size.x - p_preview_width - 40
	var board_aspect_ratio : float = available_width / available_height

	if board_aspect_ratio > display_aspect_ratio:
		return available_height / float(Display.size.y)
	return available_width / float(Display.size.x)

func animate_board_scale(p_preview_width : float) -> void:
	boards_container.scale = Vector2.ONE * get_board_scale_factor(p_preview_width)

func set_preview_list_size() -> void:
	preview_list.size.y = get_viewport_rect().size.y - preview_list.global_position.y
	preview_list.position.x = size.x - preview_list.size.x
	toggle_preview_panel.position.x = preview_list.position.x - toggle_preview_panel.size.x
	toggle_preview_panel.position.y = preview_list.position.y + 4.0 * toggle_preview_panel.size.y

func _on_resized() -> void:
	if is_node_ready():
		set_preview_list_size()
		set_boards_size()

#
# Delete all clones from display board
#
func clear_display() -> void:
	var displayed_widgets : Array = Display.presentation_screen.get_children()
	if not displayed_widgets.is_empty():
		var tween : Tween = create_tween()
		for widget : Widget in displayed_widgets:
			tween.set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(widget, "modulate:a", 0.0, 0.2)
		await tween.finished
		if is_instance_valid(displayed_widgets):
			for widget : Widget in displayed_widgets:
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
	
## Duplicate board and all widgets on a new board
func duplicate_board(p_index : int) -> void:
	var new_board : Board = packed_board.instantiate()
	board_signal_connect(new_board)
	var duplicated_board : Board = boards[p_index]
	duplicated_board.unfocus()
	boards_container.add_child(new_board)
	boards_container.move_child(new_board, 0)
	for widget in duplicated_board.get_widgets():
		duplicated_board.copy_widget_to_board(widget, new_board)

	boards.insert(p_index + 1, new_board)

	await get_tree().process_frame
	preview_list.create_item(p_index + 1, boards[p_index + 1].viewport.get_texture())
	change_board(p_index + 1)
	
## Show a confirmation dialog when board deletion is requested
func delete_confirm(p_index : int) -> void:
	# Cannot delete last board
	if boards.size() <= 1:
		return
	delete_confirmation_dialog.popup_centered()
	delete_confirmation_dialog.dialog_text = "Are you sure you want to delete page %s?" % str(p_index + 1)
	delete_index = p_index

## Delete board at p_index
func delete_board(p_index : int = delete_index) -> void:
	if p_index < 0:
		return
	var offset : int = -1 if  p_index < current_board else 0
		
	var removed_board : Board = boards[p_index]
	boards.remove_at(p_index)
	emit_signal("boards_changed", current_board, boards.size())
	

	if current_board + offset == p_index:
		change_board(current_board + offset)
	
	removed_board.queue_free()
	
	preview_list.delete_item(p_index)
	preview_list.select(current_board)


func _on_preview_list_item_moved(from_index : int , to_index : int) -> void:

	if from_index < to_index:
		boards.insert(to_index + 1, boards[from_index])
		boards.remove_at(from_index)
	else:
		boards.insert(to_index, boards[from_index])
		boards.remove_at(from_index + 1)

	change_board(to_index)

func board_signal_connect(p_board : Board) -> void:
	p_board.connect("mouse_entered", preview_list._on_mouse_exit_detected)
	p_board.connect("widgets_count_modified", main_menu._on_widgets_count_modified)
func _on_mouse_entered() -> void:
	preview_list._on_mouse_exit_detected()


func _on_toggle_preview_toggled(p_toggled_on : bool) -> void:
	var viewport_width : float =  get_viewport_rect().size.x
	var tween : Tween = create_tween()
	tween.set_parallel().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
	
	if p_toggled_on:
		tween.tween_property(preview_list, "position:x", viewport_width, 0.5)
		tween.tween_property(toggle_preview_panel, "position:x", viewport_width - toggle_preview_panel.size.x, 0.5)
		tween.tween_method(animate_board_scale, preview_list.size.x, 0.0, 0.5)
	else:
		tween.tween_method(animate_board_scale, 0.0, preview_list.size.x, 0.5)
		tween.tween_property(preview_list, "position:x", viewport_width - preview_list.size.x, 0.5)
		tween.tween_property(toggle_preview_panel, "position:x", viewport_width - preview_list.size.x - toggle_preview_panel.size.x, 0.5)
