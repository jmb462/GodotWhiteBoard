extends Control
class_name MainWindow

## Emitted when board is created or deleted or when current board changed.
signal boards_changed(current_board : int, total_boards : int)

## Document data resource
var document : Document = null

## Array of Board
var boards : Array[Board] = []

## Current board
var current_board : Board = null

## Curent board index
var current_board_index : int = -1

## Index of the board when delete board is requested
var delete_index : int = -1

## A new document is loading into boards array
var is_loading : bool = false

@onready var board_page : Control = $VBox/BoardPage
@onready var boards_container : Control = $VBox/BoardPage/BoardsContainer
@onready var preview_list : AnimatedList = $VBox/BoardPage/PreviewList
@onready var main_menu : PanelContainer = $VBox/MainMenu
@onready var mask_panel : Panel = $MaskPanel
@onready var tool_palett : Panel = $ToolPalett
@onready var document_manager : DocumentManager = $VBox/DocumentManager


@onready var delete_confirmation_dialog : ConfirmationDialog = $DeleteConfirmationDialog
@onready var clear_confirmation_dialog : ConfirmationDialog = $ClearConfirmationDialog
@onready var toggle_preview_panel : Panel = $TogglePreviewPanel

@onready var packed_board : PackedScene = preload("res://Board/Board.tscn")

## Initialization.
func _ready() -> void:
	_on_resized()
	get_tree().get_root().connect("files_dropped", _on_drop)
	create_new_document()
	

## Initialize a new empty Document.
func create_new_document() -> void:
	reset_all()	
	document = Document.new()
	G.set_document_folder_path(document)
	add_board(current_board_index)

## Reset board
func reset_all() -> void:
	boards.clear()
	preview_list.clear()
	current_board = null
	current_board_index = -1
	delete_index = -1
	is_loading = false	

## Callback : File dropped on current board.
func _on_drop(data : Variant) -> void:
	if not boards_container.is_visible_in_tree():
		return
	var image : Image = Image.new()
	image.load(data[0])
	current_board.create_image_widget(get_viewport_rect().size/2.0,  image)


## Called when palett pen button is pressed.
func _on_pen_pressed() -> void:
	current_board.set_mode(G.BOARD_MODE.PEN)

## Called when palett text button is pressed.
func _on_palette_text_pressed() -> void:
	current_board.set_mode(G.BOARD_MODE.TEXT_POSITION)

## Called when palett image button is pressed.
func _on_palette_image_pressed() -> void:
	current_board.set_mode(G.BOARD_MODE.IMAGE_POSITION)

## Called when palett arrow button is pressed.
func _on_palette_pointer_pressed() -> void:
	current_board.set_mode(G.BOARD_MODE.NONE)

## Called when palett paste button is pressed
func _on_palette_paste_pressed() -> void:
	if DisplayServer.clipboard_has_image():
		current_board.set_mode(G.BOARD_MODE.PASTE_IMAGE)
		current_board.create_image_widget(get_viewport_rect().size / 2.0, DisplayServer.clipboard_get_image())
	elif DisplayServer.clipboard_has():
		current_board.set_mode(G.BOARD_MODE.PASTE_TEXT)
		var text_widget : TextWidget = current_board.create_text_widget()
		text_widget.set_text(DisplayServer.clipboard_get())
		text_widget.position = (current_board.size - text_widget.size) / 2.0
		text_widget.synchronize()

## Create a new board.
func add_board(p_index : int) -> Board:
	if is_instance_valid(current_board):
		if not is_loading:
			save_thumbnail(current_board)
	var new_board : Board = packed_board.instantiate()
	board_signal_connect(new_board)
	boards_container.add_child(new_board)
	if is_instance_valid(current_board):
		current_board.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		current_board.hide()
		
	boards.insert(p_index + 1, new_board)
	
	current_board_index = p_index + 1
	
	set_current_board(new_board)
	
	var preview_texture : ViewportTexture = new_board.viewport.get_texture()
	var preview_item : AnimatedItem = preview_list.create_item(p_index + 1, preview_texture, not is_loading)
	preview_list.select(preview_item.index)
	
	clear_display()
	set_preview_list_size()
	set_boards_size()
	if not is_loading:
		save_thumbnail(current_board)
	return current_board

## Callback : New board requested.
func _on_new_board_pressed() -> void:
	add_board(current_board_index)

## Callback : Previous board requested.
func _on_previous_board_pressed() -> void:
	change_board(current_board_index - 1)
	
## Callback : Next board requested.
func _on_next_board_pressed() -> void:
	change_board(current_board_index + 1)

## Switch to show board at given index.
func change_board(p_index : int) -> void:
	if p_index < 0:
		return
	current_board.set_mode(G.BOARD_MODE.NONE)
	current_board.unfocus()
	if not is_loading:
		save_thumbnail(current_board)	
	clear_display()
	current_board_index = p_index
	
	if current_board_index >= boards.size():
		current_board_index = boards.size() - 1
	
	set_current_board(boards[current_board_index])
		
	synchronize_display()

	show_only_current_board()
	
	preview_list.select(current_board_index)

## Set the p_board Board has current one.
func set_current_board(p_board : Board) -> void:
	current_board = p_board
	current_board.activate()
	emit_signal("boards_changed", current_board_index, boards.size())

## Show the current board and hide all others.
func show_only_current_board() -> void:
	for i : int in boards.size():
		boards[i].visible = i == current_board_index
		if boards[i].visible :
			preview_list.set_item_texture(i, boards[i].viewport.get_texture())

## Show a confirmation dialog on clear board request.
func clear_board_confirm() -> void:
	clear_confirmation_dialog.popup_centered()

## Delete all widget of current board.
func clear_board() -> void:
	for widget : Widget in current_board.get_widgets():
		widget.delete()

func _on_palette_freeze_pressed() -> void:
	pass

## Callback : boards container has been resized/
func _on_boards_resized() -> void:
	if is_instance_valid(boards_container):
		for each_board : Board in boards:
			each_board.custom_minimum_size = current_board.size

## Set boards container size to fit available space.
func set_boards_size() -> void:
	boards_container.size = Display.size
	var preview_width : float = 0.0
	if preview_list.visible:
		preview_width = preview_list.size.x
	boards_container.scale = Vector2.ONE * get_board_scale_factor(preview_width)
	boards_container.position.x = (size.x - boards_container.size.x * boards_container.scale.x - preview_width) / 2.0


## Returns board scale factor allowing to fit available space.
func get_board_scale_factor(p_preview_width : float) -> float:
	var display_aspect_ratio : float = float(Display.size.x)/float(Display.size.y)
	
	var available_height : float = size.y - G.HEIGHT_MARGIN
	if main_menu.visible:
		available_height -= main_menu.size.y
		
	var available_width : float = size.x - p_preview_width - G.WIDTH_MARGIN
	var board_aspect_ratio : float = available_width / available_height

	if board_aspect_ratio > display_aspect_ratio:
		return available_height / float(Display.size.y)
	return available_width / float(Display.size.x)


## Callback tweener : adapt boards container size while tweening board scale.
func animate_board_scale(p_preview_width : float) -> void:
	boards_container.scale = Vector2.ONE * get_board_scale_factor(p_preview_width)

## Adapt preview list size
func set_preview_list_size() -> void:
	preview_list.size.y = get_viewport_rect().size.y - preview_list.global_position.y
	preview_list.position.x = size.x - preview_list.size.x
	toggle_preview_panel.position.x = preview_list.position.x - toggle_preview_panel.size.x
	toggle_preview_panel.position.y = preview_list.position.y + 4.0 * toggle_preview_panel.size.y

## Adapt panel size on main window resized.
func _on_resized() -> void:
	if is_node_ready():
		set_preview_list_size()
		set_boards_size()


## Delete all clones from display board.
func clear_display() -> void:
	var displayed_widgets : Array = Display.presentation_screen.get_children()
	for widget : Widget in displayed_widgets:
		if is_instance_valid(widget):
			if is_instance_valid(widget.master):
				widget.master.clone = null
			widget.queue_free()


## Clone each widget of board on display screen.
func synchronize_display() -> void:
	for widget : Widget in current_board.get_widgets():
		current_board.clone_widget(widget)
	
## Duplicate board and all widgets on a new board.
func duplicate_board(p_index : int) -> void:
	var new_board : Board = packed_board.instantiate()
	board_signal_connect(new_board)
	var duplicated_board : Board = boards[p_index]
	duplicated_board.unfocus()
	boards_container.add_child(new_board)
	boards_container.move_child(new_board, 0)
	for widget : Widget in duplicated_board.get_widgets():
		duplicated_board.copy_widget_to_board(widget, new_board)

	boards.insert(p_index + 1, new_board)

	preview_list.create_item(p_index + 1, boards[p_index + 1].viewport.get_texture())
	change_board(p_index + 1)
	
## Show a confirmation dialog when board deletion is requested.
func delete_confirm(p_index : int) -> void:
	# Cannot delete last board
	if boards.size() <= 1:
		return
	delete_confirmation_dialog.popup_centered()
	delete_confirmation_dialog.dialog_text = "Are you sure you want to delete page %s?" % str(p_index + 1)
	delete_index = p_index

## Delete board at p_index.
func delete_board(p_index : int = delete_index) -> void:
	if p_index < 0:
		return
	var offset : int = -1 if  p_index < current_board_index else 0
		
	var removed_board : Board = boards[p_index]
	delete_thumbnail(removed_board.uid)
	boards.remove_at(p_index)
	emit_signal("boards_changed", current_board_index, boards.size())
	
	if current_board_index + offset == p_index:
		change_board(current_board_index + offset)
	
	delete_thumbnail(removed_board.uid)
	removed_board.queue_free()
	
	preview_list.delete_item(p_index)
	preview_list.select(current_board_index)

func delete_thumbnail(p_board_uid : int) -> void:
	if DirAccess.remove_absolute(G.get_board_thumbnail_path(p_board_uid)) != OK:
		print("Cannot delete board thumbnail at ", G.get_board_thumbnail_path(p_board_uid))

## Callback : a preview item has been drag'n'dropped to a new index.
func _on_preview_list_item_moved(from_index : int , to_index : int) -> void:
	if from_index < to_index:
		boards.insert(to_index + 1, boards[from_index])
		boards.remove_at(from_index)
	else:
		boards.insert(to_index, boards[from_index])
		boards.remove_at(from_index + 1)

## Connect all board signals needed.
func board_signal_connect(p_board : Board) -> void:
	p_board.connect("mouse_entered", preview_list._on_mouse_exit_detected)
	p_board.connect("widgets_count_modified", main_menu._on_widgets_count_modified)

## Ensure that mouse exited signal has been send to preview_list if entering board.
func _on_mouse_entered() -> void:
	preview_list._on_mouse_exit_detected()

## Toggle preview panel.
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

## Reset to a single empty board.
func reset() -> void:
	for each_board : Board in boards:
		each_board.queue_free()
	boards.clear()
	preview_list.clear()
	current_board_index = -1


## Load data from Document resource, instanciate boards and widgets.
func load_document(p_document : Document, p_board_index : int = 0) -> void:
	document = p_document
	G.set_document_folder_path(document)
	if is_loading:
		return
	is_loading = true
	reset()
	mask_boards()
	for board_data : BoardData in p_document.boards:
		board_data.restore(add_board(current_board_index))
		var image : Image = Image.load_from_file(document.get_preview_path(current_board_index))
		preview_list.set_item_texture(current_board_index, ImageTexture.create_from_image(image))
	change_board(p_board_index)
	mask_boards(false, p_document.boards.size())
	

## Toggle opaque white overlay on top of boards stack.
func mask_boards(p_masked : bool = true, duration : float = 0.0) -> void:
	if p_masked:
		mask_panel.global_position = current_board.global_position
		mask_panel.size = current_board.size * boards_container.scale
		mask_panel.show()
	else:
		await get_tree().create_timer(0.01 * duration).timeout
		mask_panel.hide()
		is_loading = false

## Save board thumbnail snapshot to disk.
func save_thumbnail(p_board : Board) -> void:
	p_board.unfocus()
	var thumbnail : Image = p_board.get_thumbnail()
	save_document()
	thumbnail.save_jpg(G.get_board_thumbnail_path(p_board.uid))


## Save boards to Document resource.
func save_document() -> void:
	if not DirAccess.dir_exists_absolute(G.document_folder_path):
		DirAccess.make_dir_recursive_absolute(G.document_folder_path)
	document.store(boards)
	var error : Error = ResourceSaver.save(document, G.get_document_path())
	if error != OK:
		print("Error while saving boards to disk (Error %s)" % error)

## Save document before exiting application.
func _on_tree_exiting() -> void:
	print("exiting")
	if not document.is_empty():
		save_thumbnail(current_board)
		#await self.saved
		print("on enregistre l'enregistrement")
	else:
		print("on supprime l'enregistrement")

## Callback : Board button has been pressed in main menu.
func _on_main_menu_document_manager_requested() -> void:
	save_thumbnail(current_board)
	switch_to_document_manager(document.uid, current_board.uid)
	
## Callback : Board button has been pressed in main menu.
func _on_main_menu_board_requested() -> void:
	switch_to_boards()

## Callback : Board has been double-clicked in document manager.
func _on_document_manager_document_requested(p_document : Document, p_board_index : int) -> void:
	switch_to_boards()
	load_document(p_document, p_board_index)

## Toggle visibility of board page and documents page nodes.
func switch_to_boards() -> void:
	get_tree().call_group(G.BOARD_GROUP, "show")
	get_tree().call_group(G.DOCUMENTS_GROUP, "hide")

## Toggle visibility of board page and documents page nodes.
func switch_to_document_manager(p_document_uid : int, p_current_board_uid : int) -> void:
	get_tree().call_group(G.BOARD_GROUP, "hide")
	get_tree().call_group(G.DOCUMENTS_GROUP, "show")
	document_manager.activate(p_document_uid, p_current_board_uid)


func _on_main_menu_new_document_requested() -> void:
	create_new_document()
	DirAccess.copy_absolute(G.EMPTY_THUMBNAIL, G.get_board_thumbnail_path(document.boards[0].uid))
	document_manager.activate(document.uid, document.boards[0].uid, true)

