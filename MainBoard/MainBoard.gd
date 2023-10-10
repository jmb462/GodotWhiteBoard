extends Control

@onready var visible_background : ColorRect = $VisibleBackground
@onready var vbox : VBoxContainer = $VBoxContainer
@onready var rect_preview : Panel = $RectPreview

@onready var packed_widget : PackedScene = preload("res://Widget/TextWidget/TextWidget.tscn")

enum BOARD_MODE { NONE, TEXT_POSITION, TEXT_SIZE, PEN, PASTE_IMAGE}
var board_mode : BOARD_MODE = BOARD_MODE.NONE

var new_widget_rect : Rect2 = Rect2()

var focused_widget : Widget = null

func _ready() -> void:
	_on_resized()


func _on_resized() -> void:
	if is_node_ready():
		# Visible background delimits the presentation zone
		# Need to take care of aspect ratio of the presentation screen
		visible_background.size.y = get_window().size.y
		visible_background.size.x = get_window().size.y * 4.0 / 3.0
		visible_background.position = Vector2((get_window().size.x - visible_background.size.x) / 2.0, 0.0)
		vbox.custom_minimum_size.x = visible_background.position.x


#
#	Text button has been pressed for widget creation
#
func _on_text_pressed() -> void:
	board_mode = BOARD_MODE.TEXT_POSITION
	visible_background.set_default_cursor_shape(CURSOR_CROSS)


#
#	Image clipboard button pressed
#
func _on_paste_image_pressed():
	pass
#	if DisplayServer.clipboard_has_image():
#		board_mode = BOARD_MODE.PASTE_IMAGE
#		print("image !!")
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
					
			if board_mode == BOARD_MODE.TEXT_SIZE:
				if not event.is_pressed():
					# Left button has been released
					# Time to create the widget
					create_text_widget()
					rect_preview.hide()
					visible_background.set_default_cursor_shape(CURSOR_ARROW)
					board_mode = BOARD_MODE.NONE
	
	if event is InputEventMouseMotion:
		if board_mode == BOARD_MODE.TEXT_SIZE:
			# Setting size of future widget by dragging preview rectangle
			if new_widget_rect.position.x > event.position.x:
				var right : float = new_widget_rect.position.x
				new_widget_rect.position.x = event.position.x
				new_widget_rect.size.x = abs(right - event.position.x)
			if new_widget_rect.position.y > event.position.y:
				var bottom : float = new_widget_rect.position.y
				new_widget_rect.position.y = event.position.y
				new_widget_rect.size.y = abs(bottom - event.position.y)
			else:
				new_widget_rect.size += event.relative
			
			rect_preview.position = new_widget_rect.position + visible_background.position
			rect_preview.size = new_widget_rect.size


#
#	New widget creation
#
func create_text_widget() -> void:
	#Create master widget on control screen
	var new_widget : Widget = packed_widget.instantiate()
	visible_background.add_child(new_widget)
	new_widget.position = new_widget_rect.position
	new_widget.size = new_widget_rect.size
	new_widget_rect = Rect2()
	set_focus(new_widget)
	new_widget.connect("focus_requested", set_focus)
	clone_widget(new_widget)



#
# Clone a widget from the control screen to the presentation screen
#
func clone_widget(p_widget : Widget) -> void:
	var new_clone_widget : Widget = packed_widget.instantiate()
	Display.add_child(new_clone_widget)
	new_clone_widget.position = p_widget.position
	new_clone_widget.size = p_widget.size
	# Store a reference to the cloned widget in the master widget
	p_widget.set_clone(new_clone_widget)


#
# Draw a size preview for widget creation by dragging
#
func drag_size_preview(p_position : Vector2) -> void:
	new_widget_rect.position = p_position
	board_mode = BOARD_MODE.TEXT_SIZE
	rect_preview.position = new_widget_rect.position + visible_background.position
	rect_preview.size = new_widget_rect.size
	rect_preview.show()

#
# Set focus on widget (and unfocus previous focused widget)
#
func set_focus(p_widget : Widget) -> void:
	unfocus()
	focused_widget = p_widget
	p_widget.set_focus(true)
	
	
#
# Unfocus widget
#
func unfocus(p_widget  : Widget = focused_widget) -> void:
	if is_instance_valid(p_widget):
		p_widget.set_focus(false)
		focused_widget = null



