extends Control

@onready var visible_background = $VisibleBackground
@onready var vbox = $VBoxContainer
@onready var rect_preview = $RectPreview

@onready var packed_widget : PackedScene = preload("res://Widget/Widget.tscn")

enum BOARD_MODE { NONE, TEXT_POSITION, TEXT_SIZE, PEN }
var board_mode = BOARD_MODE.NONE
var new_widget_rect : Rect2 = Rect2()

func _ready() -> void:
	_on_resized()


func _on_resized():
	if is_node_ready():
		visible_background.size.y = get_window().size.y
		visible_background.size.x = get_window().size.y * 4.0 / 3.0
		visible_background.position = Vector2((get_window().size.x - visible_background.size.x) / 2.0, 0.0)
		vbox.custom_minimum_size.x = visible_background.position.x


func _on_text_pressed():
	board_mode = BOARD_MODE.TEXT_POSITION
	visible_background.set_default_cursor_shape(CURSOR_CROSS)

func _on_pen_pressed():
	board_mode = BOARD_MODE.PEN


func _on_visible_background_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if board_mode == BOARD_MODE.TEXT_POSITION:
				if event.is_pressed():
					new_widget_rect.position = event.position
					board_mode = BOARD_MODE.TEXT_SIZE
					rect_preview.position = new_widget_rect.position + visible_background.position
					rect_preview.size = new_widget_rect.size
					rect_preview.show()
					
			if board_mode == BOARD_MODE.TEXT_SIZE:
				if not event.is_pressed():
					create_text_widget()
					rect_preview.hide()
					visible_background.set_default_cursor_shape(CURSOR_ARROW)
					board_mode = BOARD_MODE.NONE
	
	if event is InputEventMouseMotion:
		if board_mode == BOARD_MODE.TEXT_SIZE:
			if new_widget_rect.position.x > event.position.x:
				var right = new_widget_rect.position.x
				new_widget_rect.position.x = event.position.x
				new_widget_rect.size.x = abs(right - event.position.x)
			if new_widget_rect.position.y > event.position.y:
				var bottom = new_widget_rect.position.y
				new_widget_rect.position.y = event.position.y
				new_widget_rect.size.y = abs(bottom - event.position.y)
			else:
				new_widget_rect.size += event.relative
			
			rect_preview.position = new_widget_rect.position + visible_background.position
			rect_preview.size = new_widget_rect.size

func create_text_widget():
	var new_widget = packed_widget.instantiate()
	visible_background.add_child(new_widget)
	new_widget.position = new_widget_rect.position
	new_widget.size = new_widget_rect.size

	
	var new_clone_widget : PanelContainer = packed_widget.instantiate()
	Display.add_child(new_clone_widget)
	new_clone_widget.position = new_widget.position
	new_clone_widget.size = new_widget.size
	new_widget.set_clone(new_clone_widget)

	new_widget_rect = Rect2()
