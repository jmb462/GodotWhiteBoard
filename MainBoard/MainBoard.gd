extends Control

@onready var visible_background : ColorRect = $VisibleBackground
@onready var vbox : VBoxContainer = $VBoxContainer
@onready var preview_anchor : Control = $PreviewAnchor
@onready var rect_preview : Panel = $PreviewAnchor/RectPreview

@onready var packed_text_widget : PackedScene = preload("res://Widget/TextWidget/TextWidget.tscn")
@onready var packed_image_widget : PackedScene = preload("res://Widget/ImageWidget/ImageWidget.tscn")
@onready var packed_group_widget : PackedScene = preload("res://Widget/GroupWidget/GroupWidget.tscn")

enum BOARD_MODE { NONE, SELECT, TEXT_POSITION, TEXT_SIZE, PEN, IMAGE_POSITION, IMAGE_SIZE, PASTE_IMAGE}
var board_mode : BOARD_MODE = BOARD_MODE.NONE

var preview_rect : Rect2 = Rect2()

var focused_widget : Array[Widget] = []

var temp_group : Widget = null

func _ready() -> void:
	_on_resized()
	get_tree().get_root().connect("files_dropped", _on_drop)


func _on_resized() -> void:
	if is_node_ready():
		# Visible background delimits the presentation zone
		# Need to take care of aspect ratio of the presentation screen
		visible_background.size.y = get_window().size.y
		visible_background.size.x = get_window().size.y * 4.0 / 3.0
		visible_background.position = Vector2((get_window().size.x - visible_background.size.x) / 2.0, 0.0)
		preview_anchor.position = visible_background.position
		vbox.custom_minimum_size.x = visible_background.position.x


func _on_drop(data):
	var image : Image = Image.new()
	image.load(data[0])
	create_image_widget(image)

#
#	Image clipboard button pressed
#
func _on_paste_image_pressed():
	if DisplayServer.clipboard_has_image():
		board_mode = BOARD_MODE.PASTE_IMAGE
		create_image_widget(DisplayServer.clipboard_get_image())

#
#	Free draw button has been pressed
#
func _on_pen_pressed() -> void:
	board_mode = BOARD_MODE.PEN


func _on_visible_background_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if is_instance_valid(temp_group):
					ungroup()
				unfocus()
			if board_mode == BOARD_MODE.TEXT_POSITION:
				if event.is_pressed():
					drag_size_preview(event.position)
			elif board_mode == BOARD_MODE.IMAGE_POSITION:
				if event.is_pressed():
					drag_size_preview(event.position)	
			elif board_mode == BOARD_MODE.TEXT_SIZE:
				if not event.is_pressed():
					# Left button has been released
					# Time to create the widget
					create_text_widget()
					rect_preview.hide()
					visible_background.set_default_cursor_shape(CURSOR_ARROW)
					board_mode = BOARD_MODE.NONE
			elif board_mode == BOARD_MODE.IMAGE_SIZE:
				if not event.is_pressed():
					# Left button has been released
					# Time to create the widget
					create_image_widget()
					rect_preview.hide()
					visible_background.set_default_cursor_shape(CURSOR_ARROW)
					board_mode = BOARD_MODE.NONE
			elif board_mode == BOARD_MODE.NONE:
				if event.is_pressed():
					board_mode = BOARD_MODE.SELECT
					rect_preview.position = event.position
					preview_rect.position = event.position
					preview_rect.size = Vector2.ZERO

			elif board_mode == BOARD_MODE.SELECT:
				if not event.is_pressed():
					rect_preview.hide()
					preview_rect = Rect2()
					group_widgets()
					board_mode = BOARD_MODE.NONE
					
	if event is InputEventMouseMotion:
		if board_mode in [BOARD_MODE.TEXT_SIZE, BOARD_MODE.SELECT]:
			preview_rect.size += event.relative
			rect_preview.position = preview_rect.abs().position
			rect_preview.size = preview_rect.abs().size
			if board_mode == BOARD_MODE.SELECT:
				check_selected_widgets()
#	New widget creation
#
func create_text_widget() -> void:
	#Create master text widget on control screen
	var new_widget : TextWidget = packed_text_widget.instantiate()
	visible_background.add_child(new_widget)
	new_widget.position = preview_rect.abs().position
	new_widget.size = preview_rect.abs().size
	new_widget.pivot_offset = preview_rect.abs().size / 2.0
	preview_rect = Rect2()
	set_focus(new_widget)
	connect_widget_signals(new_widget)
	clone_widget(new_widget)

func create_image_widget(p_image : Image = null) -> void:
	#Create master image widget on control screen
	var new_widget : ImageWidget = packed_image_widget.instantiate()
	visible_background.add_child(new_widget)
	new_widget.position = preview_rect.position
	new_widget.size = preview_rect.size
	new_widget.pivot_offset = preview_rect.size / 2.0
	preview_rect = Rect2()
	set_focus(new_widget)
	connect_widget_signals(new_widget)
	if is_instance_valid(p_image):
		new_widget.set_texture(p_image)
		new_widget.position = (visible_background.size - new_widget.size) / 2.0
	clone_widget(new_widget)
	board_mode = BOARD_MODE.NONE

#
# Duplicate a widget on control screen
#
func duplicate_widget(p_widget : Widget) -> void:
	var new_widget : Widget = p_widget.duplicate()
	visible_background.add_child(new_widget)
	new_widget.position = p_widget.position + Vector2(30,30)
	new_widget.size = p_widget.size
	new_widget.visible_on_presentation_screen = p_widget.visible_on_presentation_screen
	new_widget.locked = p_widget.locked
	new_widget.editable = p_widget.editable
	set_focus(new_widget)
	connect_widget_signals(new_widget)
	clone_widget(new_widget)
	
#
# Clone a widget from the control screen to the presentation screen
#
func clone_widget(p_widget : Widget) -> void:
	var new_clone_widget : Widget = p_widget.duplicate(DUPLICATE_USE_INSTANTIATION)
	Display.presentation_screen.add_child(new_clone_widget)

	# Store a reference to the cloned widget in the master widget
	p_widget.set_clone(new_clone_widget)

#
#
#
func connect_widget_signals(p_widget : Widget) -> void:
	p_widget.connect("focus_requested", set_focus)
	p_widget.connect("duplicate_requested", duplicate_widget)
	p_widget.connect("layer_change_requested", change_layer)
	p_widget.connect("widget_deleted", _on_widget_deleted)
#
# Draw a size preview for widget creation by dragging
#
func drag_size_preview(p_position : Vector2) -> void:
	preview_rect.position = p_position
	match board_mode:
		BOARD_MODE.TEXT_POSITION:
			board_mode = BOARD_MODE.TEXT_SIZE
		BOARD_MODE.IMAGE_POSITION:
			board_mode = BOARD_MODE.IMAGE_SIZE
	rect_preview.position = preview_rect.abs().position	
	rect_preview.size = preview_rect.abs().size
	rect_preview.show()

func _on_widget_deleted(p_widget : Widget) -> void:
	print("widget deleted ", p_widget)
	unfocus(p_widget)

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
# Unfocus a specific widget or all if p_widget is null
#
func unfocus(p_widget  : Widget = null) -> void:
	if is_instance_valid(p_widget):
		focused_widget.remove_at(focused_widget.find(p_widget))
		p_widget.set_focus(false)		
	else:
		for widget in focused_widget:
			widget.set_focus(false)
		focused_widget.clear()


func change_layer(p_widget : Widget, p_direction : int) -> void:
	if p_widget.get_index() == 0 and p_direction == -1:
		return
	visible_background.move_child(p_widget, p_widget.get_index() + p_direction)
	Display.presentation_screen.move_child(p_widget.clone, p_widget.get_index())

func check_selected_widgets():
	unfocus()
	rect_preview.show()
	for widget in visible_background.get_children():
		if widget.get_rect().intersects(preview_rect.abs()):
			set_focus(widget, false)

func ungroup() -> void:
	for widget in temp_group.container.get_children():
		print(widget)
		widget.pin_marker(G.MARKER.TOP_LEFT)
		var global_rotation = widget.get_global_transform().get_rotation()
		widget.reparent(visible_background)
		
		widget.rotation = global_rotation
		widget.move_to_pin()
		clone_widget(widget)
	if temp_group.is_master():
		temp_group.clone.queue_free()
	temp_group.queue_free()
	unfocus()
	
func group_widgets() -> void:
	if focused_widget.is_empty():
		return
	if focused_widget.size() == 1:
		set_focus(focused_widget[0])	
		return
	
	focused_widget.sort_custom(sort_by_index)
	
	var new_widget : GroupWidget = packed_group_widget.instantiate()
	visible_background.add_child(new_widget)
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
	
func sort_by_index(a : Widget, b : Widget) -> bool:
	if a.get_index() < b.get_index():
		return true
	return false

func get_container_rect(p_widgets : Array[Widget]) -> Rect2:
	
	var array_x : Array[float] = []
	var array_y : Array[float] = []
	for widget in p_widgets:
		for marker in [G.MARKER.TOP_LEFT, G.MARKER.TOP_RIGHT, G.MARKER.BOTTOM_LEFT, G.MARKER.BOTTOM_RIGHT]:
			array_x.append(widget.get_marker_position(marker).x)
			array_y.append(widget.get_marker_position(marker).y)
	var rect : Rect2 = Rect2(array_x.min(), array_y.min(), array_x.max() - array_x.min(), array_y.max() - array_y.min())
	rect.position -= visible_background.position
	rect.size += Vector2(8,34)
	return rect


func _on_palette_text_pressed() -> void:
	board_mode = BOARD_MODE.TEXT_POSITION
	visible_background.set_default_cursor_shape(CURSOR_CROSS)


func _on_palette_image_pressed():
	board_mode = BOARD_MODE.IMAGE_POSITION
	visible_background.set_default_cursor_shape(CURSOR_CROSS)



func _on_palette_pointer_pressed():
	board_mode = BOARD_MODE.NONE
	visible_background.set_default_cursor_shape(CURSOR_ARROW)
