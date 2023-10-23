extends SubViewportContainer
class_name Board

var temp_group : Widget = null
var focused_widget : Array[Widget] = []

var board_mode : G.BOARD_MODE = G.BOARD_MODE.NONE
var preview_rect : Rect2 = Rect2()

@onready var packed_text_widget : PackedScene = preload("res://Widget/TextWidget/TextWidget.tscn")
@onready var packed_image_widget : PackedScene = preload("res://Widget/ImageWidget/ImageWidget.tscn")
@onready var packed_group_widget : PackedScene = preload("res://Widget/GroupWidget/GroupWidget.tscn")

@onready var rect_preview : Panel = $PreviewAnchor/RectPreview
@onready var viewport : SubViewport = $SubViewport
@onready var whiteboard : Panel = $SubViewport/WhiteBoard

func _ready():
	connect_gui_input(_on_board_gui_input)
	print("viewport size ", viewport.size)
	await get_tree().process_frame
	whiteboard.size = size

func _process(_delta):
	if board_mode == G.BOARD_MODE.SELECT:
		if not Input.is_action_pressed("selection_button"):
			print("end selection by process")
			end_select()

func _on_board_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if is_instance_valid(temp_group):
					ungroup()
				unfocus()
			if board_mode == G.BOARD_MODE.TEXT_POSITION:
				if event.is_pressed():
					drag_size_preview(event.position)
			elif board_mode == G.BOARD_MODE.IMAGE_POSITION:
				if event.is_pressed():
					drag_size_preview(event.position)	
			elif board_mode == G.BOARD_MODE.TEXT_SIZE:
				if not event.is_pressed():
					# Left button has been released
					# Time to create the widget
					create_text_widget()
					rect_preview.hide()
					set_cursor(CURSOR_ARROW)
					board_mode = G.BOARD_MODE.NONE
			elif board_mode == G.BOARD_MODE.IMAGE_SIZE:
				if not event.is_pressed():
					# Left button has been released
					# Time to create the widget
					create_image_widget()
					rect_preview.hide()
					set_cursor(CURSOR_ARROW)
					board_mode = G.BOARD_MODE.NONE
			elif board_mode == G.BOARD_MODE.NONE:
				if event.is_pressed():
					board_mode = G.BOARD_MODE.SELECT
					rect_preview.position = event.position + Vector2(0, global_position.y)
					preview_rect.position = event.position + Vector2(0, global_position.y)
					preview_rect.size = Vector2.ZERO
				
					
	if event is InputEventMouseMotion:
		if board_mode in [G.BOARD_MODE.TEXT_SIZE, G.BOARD_MODE.SELECT]:
			preview_rect.size += event.relative
			rect_preview.position = preview_rect.abs().position
			rect_preview.size = preview_rect.abs().size
			if board_mode == G.BOARD_MODE.SELECT:
				check_selected_widgets()

func adapt_size(p_size : Vector2) -> void:
	print("adpat resized")
	size = p_size
	viewport.size = p_size
	
func add(p_node : Node, p_board : Board = self) -> void:
	p_board.whiteboard.add_child(p_node)

func get_widgets() -> Array[Node]:
	return whiteboard.get_children()

func set_cursor(p_cursor : CursorShape) -> void:
	whiteboard.set_default_cursor_shape(p_cursor)

func get_whiteboard_rect() -> Rect2:
	return whiteboard.get_global_rect()

func change_layer(p_widget : Widget, p_layer : int) -> void:
	whiteboard.move_child(p_widget, p_layer)

func set_child(p_widget : Widget) -> void:
	p_widget.reparent(whiteboard)

func connect_gui_input(p_callback : Callable) -> void:
	whiteboard.connect("gui_input", p_callback)

func end_select() -> void:
	rect_preview.hide()
	preview_rect = Rect2()
	group_widgets()
	board_mode = G.BOARD_MODE.NONE

func ungroup() -> void:
	for widget in temp_group.container.get_children():
		print(widget)
		widget.pin_marker(G.MARKER.TOP_LEFT)
		var global_rotation = widget.get_global_transform().get_rotation()
		set_child(widget)
		
		widget.rotation = global_rotation
		widget.move_to_pin()
		clone_widget(widget)
	if temp_group.is_master():
		temp_group.clone.queue_free()
	temp_group.queue_free()
	unfocus()

#
# Unfocus a specific widget or all if p_widget is null
#
func unfocus(p_widget  : Widget = null) -> void:
	if is_instance_valid(p_widget):
		focused_widget.remove_at(focused_widget.find(p_widget))
		p_widget.set_focus(false)		
	else:
		for widget in focused_widget:
			if is_instance_valid(widget):
				widget.set_focus(false)
		focused_widget.clear()

#
# Draw a size preview for widget creation by dragging
#
func drag_size_preview(p_position : Vector2) -> void:
	preview_rect.position = p_position
	match board_mode:
		G.BOARD_MODE.TEXT_POSITION:
			board_mode = G.BOARD_MODE.TEXT_SIZE
		G.BOARD_MODE.IMAGE_POSITION:
			board_mode = G.BOARD_MODE.IMAGE_SIZE
	rect_preview.position = preview_rect.abs().position	
	rect_preview.size = preview_rect.abs().size
	rect_preview.show()

#
# Clone a widget from the control screen to the presentation screen
#
func clone_widget(p_widget : Widget) -> void:
	var new_clone_widget : Widget = p_widget.duplicate(DUPLICATE_USE_INSTANTIATION)
	Display.presentation_screen.add_child(new_clone_widget)

	# Store a reference to the cloned widget in the master widget
	p_widget.set_clone(new_clone_widget)

#
#	New widget creation
#
func create_text_widget() -> TextWidget:
	#Create master text widget on control screen
	var new_widget : TextWidget = packed_text_widget.instantiate()
	add(new_widget)
	new_widget.position = preview_rect.abs().position
	new_widget.size = preview_rect.abs().size
	new_widget.pivot_offset = preview_rect.abs().size / 2.0
	preview_rect = Rect2()
	set_focus(new_widget)
	connect_widget_signals(new_widget)
	clone_widget(new_widget)
	return new_widget
	
func create_image_widget(p_image : Image = null) -> void:
	#Create master image widget on control screen
	var new_widget : ImageWidget = packed_image_widget.instantiate()
	add(new_widget)
	new_widget.position = preview_rect.position
	new_widget.size = preview_rect.size
	new_widget.pivot_offset = preview_rect.size / 2.0
	preview_rect = Rect2()
	set_focus(new_widget)
	connect_widget_signals(new_widget)
	if is_instance_valid(p_image):
		new_widget.set_texture(p_image)
		new_widget.position = (size - new_widget.size) / 2.0
	clone_widget(new_widget)
	board_mode = G.BOARD_MODE.NONE

func check_selected_widgets():
	unfocus()
	rect_preview.show()
	for widget in get_widgets():
		var rect = widget.get_rect()
		rect.position += Vector2(0, global_position.y)
		if rect.intersects(preview_rect.abs()):
			set_focus(widget, false)

func group_widgets() -> void:
	if focused_widget.is_empty():
		return
	if focused_widget.size() == 1:
		set_focus(focused_widget[0])	
		return
	
	focused_widget.sort_custom(sort_by_index)
	
	var new_widget : GroupWidget = packed_group_widget.instantiate()
	add(new_widget)
	var rect : Rect2 = get_container_rect(focused_widget)
	new_widget.position = rect.position
	new_widget.size = rect.size
	new_widget.pivot_offset = preview_rect.size / 2.0
	connect_widget_signals(new_widget)
	new_widget.position -= Vector2(4,30)
	
	for widget in focused_widget:
		widget.pin_marker(G.MARKER.TOP_LEFT)
		widget.reparent(new_widget.container)
		widget.group_into(new_widget)
		if widget.is_master():
			widget.clone.queue_free()
	
	await get_tree().process_frame
	
	for widget in focused_widget:
		widget.move_to_pin()
	
	set_focus(new_widget)
	temp_group = new_widget
	clone_widget(new_widget)
	
	#
# Set focus on widget (and unfocus previous focused widget)
#
func set_focus(p_widget : Widget, p_exclusive = true) -> void:
	if is_instance_valid(p_widget.grouped_in):
		set_focus(p_widget.grouped_in)
		return
	if p_exclusive:
		unfocus()
	if not p_widget in focused_widget:
		focused_widget.append(p_widget)
		p_widget.set_focus(true)
	
	#
#
#
func connect_widget_signals(p_widget : Widget) -> void:
	p_widget.connect("focus_requested", set_focus)
	p_widget.connect("duplicate_requested", duplicate_widget)
	p_widget.connect("layer_change_requested", change_layer)
	p_widget.connect("widget_deleted", _on_widget_deleted)

#
#	Copy a widget on chosen board
#
func copy_widget_to_board(p_widget : Widget, p_board : Board) -> Widget:
	var new_widget : Widget = p_widget.duplicate()
	add(new_widget, p_board)
	new_widget.position = p_widget.position
	new_widget.size = p_widget.size
	new_widget.visible_on_presentation_screen = p_widget.visible_on_presentation_screen
	new_widget.locked = p_widget.locked
	new_widget.editable = p_widget.editable
	new_widget.clone = null
	p_board.connect_widget_signals(new_widget)
	return new_widget

#
# Duplicate a widget on current board
#
func duplicate_widget(p_widget : Widget) -> void:
	var new_widget : Widget = copy_widget_to_board(p_widget, self)
	new_widget.position += Vector2(30,30)
	set_focus(new_widget)
	clone_widget(new_widget)


func sort_by_index(a : Widget, b : Widget) -> bool:
	if a.get_index() < b.get_index():
		return true
	return false

func _on_widget_deleted(p_widget : Widget) -> void:
	print("widget deleted ", p_widget)
	unfocus(p_widget)

func get_container_rect(p_widgets : Array[Widget]) -> Rect2:
	
	var array_x : Array[float] = []
	var array_y : Array[float] = []
	for widget in p_widgets:
		for marker in [G.MARKER.TOP_LEFT, G.MARKER.TOP_RIGHT, G.MARKER.BOTTOM_LEFT, G.MARKER.BOTTOM_RIGHT]:
			array_x.append(widget.get_marker_position(marker).x)
			array_y.append(widget.get_marker_position(marker).y)
	var rect : Rect2 = Rect2(array_x.min(), array_y.min(), array_x.max() - array_x.min(), array_y.max() - array_y.min())
	rect.position -= position
	rect.size += Vector2(8,34)
	return rect

func set_mode(p_mode : G.BOARD_MODE) -> void:
	board_mode = p_mode
	
	match board_mode:
		G.BOARD_MODE.TEXT_POSITION, G.BOARD_MODE.IMAGE_POSITION:
			set_cursor(CURSOR_CROSS)
		_:
			set_cursor(CURSOR_ARROW)
			
func get_mode() -> G.BOARD_MODE:
	return board_mode


