extends SubViewportContainer
class_name Board

signal board_created
signal board_changed

## Emitted when a widget is added or removed from board.
signal widgets_count_modified(widgets_count : int)

## Returns if the board has changed since last thumbnail snapshot.
var is_modified : bool = false

var uid : int = 0

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

func _ready() -> void:
	connect_gui_input(_on_board_gui_input)
	emit_signal("board_created")
	if uid == 0:
		uid = ResourceUID.create_id()

func _process(_delta : float) -> void:
	if board_mode == G.BOARD_MODE.SELECT:
		if not Input.is_action_pressed("selection_button"):
			end_select()

func activate() -> void:
	unfocus()
	set_mode(G.BOARD_MODE.NONE)
	emit_signal("widgets_count_modified", whiteboard.get_child_count())

func need_to_ungroup_widget(p_event : InputEvent) -> bool:
	return is_left_mouse_click(p_event) and is_instance_valid(temp_group)

func need_to_unfocus_widgets(p_event : InputEvent) -> bool:
	return is_left_mouse_click(p_event)

func need_to_set_widget_preview_size(p_event : InputEvent) -> bool:
	return is_left_mouse_click(p_event) and board_mode == G.BOARD_MODE.TEXT_POSITION

func is_left_mouse_click(p_event : InputEvent) -> bool:
	if not p_event is InputEventMouseButton:
		return false
	if not p_event.is_pressed() or not  p_event.button_index == MOUSE_BUTTON_LEFT:
		return false
	return true

func is_left_mouse_release(p_event : InputEvent) -> bool:
	if not p_event is InputEventMouseButton:
		return false
	if p_event.is_pressed() or not  p_event.button_index == MOUSE_BUTTON_LEFT:
		return false
	return true

func need_to_place_image(p_event : InputEvent) -> bool:
	return is_left_mouse_click(p_event) and board_mode == G.BOARD_MODE.IMAGE_POSITION

func need_to_create_text_widget(p_event : InputEvent) -> bool:
	return is_left_mouse_release(p_event) and board_mode == G.BOARD_MODE.TEXT_SIZE

func need_to_start_selection(p_event : InputEvent) -> bool:
	return is_left_mouse_click(p_event) and board_mode == G.BOARD_MODE.NONE

func need_to_update_preview_rect(p_event : InputEvent) -> bool:
	return p_event is InputEventMouseMotion and board_mode in [G.BOARD_MODE.TEXT_SIZE, G.BOARD_MODE.SELECT]

func _on_board_gui_input(p_event : InputEvent) -> void:
	if need_to_ungroup_widget(p_event):
		ungroup()
		
	if need_to_unfocus_widgets(p_event):
		unfocus()
		
	if need_to_set_widget_preview_size(p_event):
		drag_size_preview(p_event.position)
		
	if need_to_place_image(p_event):
		create_image_widget(p_event.position)
		set_cursor(CURSOR_ARROW)
		board_mode = G.BOARD_MODE.NONE
		
	if need_to_create_text_widget(p_event):
		create_text_widget()
		rect_preview.hide()
		set_cursor(CURSOR_ARROW)
		board_mode = G.BOARD_MODE.NONE
	
	if need_to_start_selection(p_event):
		board_mode = G.BOARD_MODE.SELECT
		rect_preview.position = p_event.position + Vector2(0, global_position.y)
		preview_rect.position = p_event.position + Vector2(0, global_position.y)
		preview_rect.size = Vector2.ZERO
	
	if need_to_update_preview_rect(p_event):
			preview_rect.size += p_event.relative
			rect_preview.position = preview_rect.abs().position
			rect_preview.size = preview_rect.abs().size
			if board_mode == G.BOARD_MODE.SELECT:
				check_selected_widgets()

func adapt_size(p_size : Vector2) -> void:
	size = p_size
	viewport.size = p_size

func add(p_node : Node, p_board : Board = self) -> void:
	p_board.whiteboard.add_child(p_node)
	is_modified = true
	emit_signal("widgets_count_modified", p_board.whiteboard.get_child_count())

func get_widgets() -> Array[Node]:
	return whiteboard.get_children()

func set_cursor(p_cursor : CursorShape) -> void:
	whiteboard.set_default_cursor_shape(p_cursor)

func get_whiteboard_rect() -> Rect2:
	return whiteboard.get_global_rect()

## Change layer of the widget
func change_layer(p_widget : Widget, p_layer_offset : int) -> void:
	var layer_from : int = whiteboard.get_children().find(p_widget)
	var children_count : int = whiteboard.get_child_count()
	var layer_to : int = max(layer_from + p_layer_offset, 0)
	
	if layer_from == layer_to or layer_to == children_count:
		return

	var new_layer_action : ActionLayerChange = ActionLayerChange.new()
	new_layer_action.setup(self, p_widget, layer_from, layer_to)
	Manager.do_action(new_layer_action)

func set_widget_new_layer(p_widget: Widget, p_layer : int) -> void:
	whiteboard.move_child(p_widget, p_layer)
	if p_widget.is_master() and is_instance_valid(p_widget.clone):
		Display.presentation_screen.move_child(p_widget.clone, p_layer)
	is_modified = true
	_on_widget_changed()

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
	for widget : Widget in temp_group.container.get_children():
		widget.pin_marker(G.MARKER.TOP_LEFT)
		var global_rotation : float = widget.get_global_transform().get_rotation()
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
		if focused_widget.find(p_widget) != -1:
			focused_widget.remove_at(focused_widget.find(p_widget))
		p_widget.set_focus(false)
	else:
		for widget : Widget in focused_widget:
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

## Create a new TextWidget and add it to the board.
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
	emit_signal("board_changed")
	return new_widget

## Create a new ImageWidget and add it to the board.
func create_image_widget(p_position : Vector2 = Vector2(), p_image : Image = null) -> ImageWidget:
	#Create master image widget on control screen
	var new_widget : ImageWidget = packed_image_widget.instantiate()
	add(new_widget)
	new_widget.position = p_position
	set_focus(new_widget)
	connect_widget_signals(new_widget)
	if is_instance_valid(p_image):
		new_widget.set_texture(p_image)
		new_widget.position = (size - new_widget.size) / 2.0
		new_widget.pivot_offset = new_widget.size / 2.0
	clone_widget(new_widget)
	emit_signal("board_changed")
	board_mode = G.BOARD_MODE.NONE
	return new_widget

func check_selected_widgets() -> void:
	unfocus()
	rect_preview.show()
	for widget : Widget in get_widgets():
		var rect : Rect2 = widget.get_rect()
		rect.position += Vector2(0, global_position.y)
		if rect.intersects(preview_rect.abs()):
			set_focus(widget, false)

## Group the currently selected widgets into a new GroupWidget
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

	for widget : Widget in focused_widget:
		widget.pin_marker(G.MARKER.TOP_LEFT)
		widget.reparent(new_widget.container)
		widget.group_into(new_widget)
		if widget.is_master():
			widget.clone.queue_free()

	await get_tree().process_frame

	for widget : Widget in focused_widget:
		widget.move_to_pin()

	set_focus(new_widget)
	temp_group = new_widget
	clone_widget(new_widget)


## Set focus on widget (and unfocus previous focused widget).
func set_focus(p_widget : Widget, p_exclusive : bool = true) -> void:
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
	p_widget.connect("widget_changed", _on_widget_changed)

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
	unfocus(p_widget)
	_on_widget_changed()
	emit_signal("widgets_count_modified", whiteboard.get_child_count() - 1)

func _on_widget_changed() -> void:
	is_modified = true
	emit_signal("board_changed")

func get_container_rect(p_widgets : Array[Widget]) -> Rect2:

	var array_x : Array[float] = []
	var array_y : Array[float] = []
	for widget : Widget in p_widgets:
		for marker : G.MARKER in [G.MARKER.TOP_LEFT, G.MARKER.TOP_RIGHT, G.MARKER.BOTTOM_LEFT, G.MARKER.BOTTOM_RIGHT]:
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

## Returns a BoardData resource with persistant data of the board.
func get_data() -> BoardData:
	var board_data : BoardData = BoardData.new()
	board_data.store(self)
	return board_data

func restore_widgets(p_widgets_data : Array[WidgetData]) -> void:
	for widget_data : WidgetData in p_widgets_data:
		if widget_data is TextWidgetData:
			var new_widget : TextWidget = create_text_widget()
			widget_data.restore(new_widget)
		elif widget_data is ImageWidgetData:
			var new_widget : ImageWidget = create_image_widget()
			widget_data.restore(new_widget)
		else:
			print("Cannot restore a base widget")

## Returns an image of the board
func get_thumbnail() -> Image:
	var image : Image = viewport.get_texture().get_image()
	image.resize(480, 270)
	return image

func board_change() -> void:
	is_modified = true
