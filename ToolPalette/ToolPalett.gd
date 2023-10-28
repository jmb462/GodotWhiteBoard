extends Panel

signal pointer_pressed
signal text_pressed
signal image_pressed
signal pencil_pressed
signal freeze_pressed
signal paste_pressed

@onready var click_timer : Timer = $ClickTimer
@onready var v_box_container : VBoxContainer = $VBoxContainer
@onready var h_box_container : HBoxContainer = $HBoxContainer

enum PALETT_ORIENTATION { HORIZONTAL, VERTICAL }
var palett_orientation : PALETT_ORIENTATION = PALETT_ORIENTATION.VERTICAL 

var is_mouse_down : bool = false
var double_click_timer : Timer = null
var is_double_click : bool = false

func _on_gui_input(p_event : InputEvent) -> void:
	if p_event is InputEventMouseButton:
		if p_event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_down = p_event.is_pressed()
			if is_mouse_down:
				if not is_double_click:
					is_double_click = true
					click_timer.start()
				else:
					rotate_palette()
	if p_event is InputEventMouseMotion:
		if is_mouse_down:
			position += p_event.relative


func _on_text_button_down() -> void:
	emit_signal("text_pressed")


func _on_image_button_down() -> void:
	emit_signal("image_pressed")


func _on_pencil_button_down() -> void:
	emit_signal("pencil_pressed")


func _on_pointer_button_down() -> void:
	emit_signal("pointer_pressed")

func _on_paste_pressed() -> void:
	emit_signal("paste_pressed")


func _on_freeze_button_pressed() -> void:
	emit_signal("freeze_pressed")


func _on_click_timer_timeout() -> void:
	is_double_click = false

func rotate_palette() -> void:
	# Exchange panel size components
	custom_minimum_size = custom_minimum_size.orthogonal() * Vector2(1, -1)
	size = custom_minimum_size
	
	# Reparent button to the correct BoxContainer
	var containers : Array[BoxContainer] = [h_box_container, v_box_container]
	var source_container : BoxContainer = containers.pop_at(palett_orientation)
	var dest_container : BoxContainer = containers.pop_back()
	
	palett_orientation = ((palett_orientation + 1) % 2) as PALETT_ORIENTATION
	
	for child : Button in source_container.get_children():
		child.reparent(dest_container)
	
	# Prevent toolbar to be partially offscreen after changing orientation
	var border_margin : int = 20
	var to_screen_limit : Vector2 = Vector2.ZERO
	to_screen_limit.x = min((get_viewport_rect().size.x - border_margin) - (position.x + size.x), 0.0)
	to_screen_limit.y = min((get_viewport_rect().size.y - border_margin) - (position.y + size.y), 0.0)
	position += to_screen_limit
		
