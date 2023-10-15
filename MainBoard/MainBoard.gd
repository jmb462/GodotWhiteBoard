extends Control

@onready var visible_background : ColorRect = $VisibleBackground
@onready var vbox : VBoxContainer = $VBoxContainer
@onready var preview_anchor : Control = $PreviewAnchor
@onready var rect_preview : Panel = $PreviewAnchor/RectPreview

@onready var packed_text_widget : PackedScene = preload("res://Widget/TextWidget/TextWidget.tscn")
@onready var packed_image_widget : PackedScene = preload("res://Widget/ImageWidget/ImageWidget.tscn")

enum BOARD_MODE { NONE, SELECT, TEXT_POSITION, TEXT_SIZE, PEN, IMAGE_POSITION, IMAGE_SIZE, PASTE_IMAGE}
var board_mode : BOARD_MODE = BOARD_MODE.NONE

var preview_rect : Rect2 = Rect2()

var focused_widget : Array[Widget] = []

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


#
#	Text button has been pressed for widget creation
#
func _on_text_pressed() -> void:
	board_mode = BOARD_MODE.TEXT_POSITION
	visible_background.set_default_cursor_shape(CURSOR_CROSS)

func _on_image_pressed():
	board_mode = BOARD_MODE.IMAGE_POSITION
	visible_background.set_default_cursor_shape(CURSOR_CROSS)

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
					print("NEED TO GROUP")
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
	var packed_widget : PackedScene = null
	if p_widget is TextWidget:
		packed_widget = packed_text_widget
	elif p_widget is ImageWidget:
		packed_widget = packed_image_widget
	else:
		return
	var new_clone_widget : Widget = packed_widget.instantiate()
	Display.presentation_screen.add_child(new_clone_widget)
	new_clone_widget.position = p_widget.position
	new_clone_widget.size = p_widget.size
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
	if p_exclusive:
		unfocus()
	focused_widget.append(p_widget)
	p_widget.set_focus(true)
	
#
# Unfocus widget
#
func unfocus(p_widget  : Widget = null) -> void:
	if is_instance_valid(p_widget):
		focused_widget.remove_at(focused_widget.find(p_widget))
		p_widget.set_focus(false)		
	else:
		for widget in focused_widget:
			unfocus(widget)
			

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
