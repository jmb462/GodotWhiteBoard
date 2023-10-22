extends Panel

signal pointer_pressed
signal text_pressed
signal image_pressed
signal pencil_pressed
signal freeze_pressed
signal paste_pressed

var is_mouse_down : bool = false

func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_down = event.is_pressed()
	if event is InputEventMouseMotion:
		if is_mouse_down:
			position += event.relative


func _on_text_button_down():
	emit_signal("text_pressed")


func _on_image_button_down():
	emit_signal("image_pressed")


func _on_pencil_button_down():
	emit_signal("pencil_pressed")


func _on_pointer_button_down():
	emit_signal("pointer_pressed")
	


func _on_paste_pressed():
	emit_signal("paste_pressed")


func _on_freeze_button_pressed():
	emit_signal("freeze_pressed")
