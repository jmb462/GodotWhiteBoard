extends PanelContainer
class_name Widget

signal focus_requested(widget : Widget)
signal duplicate_requested(widget : Widget)
signal layer_change_requested(widget : Widget, direction : int)

@onready var buttons : Node2D = $Buttons

@onready var focus_theme : StyleBoxFlat = load("res://Styles/Widget_master_selected.tres")
@onready var unfocus_theme : StyleBoxFlat = load("res://Styles/Widget_unfocus.tres")

var focus : bool = true
var visible_on_presentation_screen : bool = true

# A locked widget cannot be resized or moved
var locked : bool = false

var editable : bool = true

var current_action : G.ACTION = G.ACTION.NONE
var resize_type : G.RESIZE = G.RESIZE.NONE
var keep_ratio : bool = false

# Reference to the same widget on presentation screen
var clone : Widget = null


func _ready() -> void :
	_on_resized()


func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not locked:
			match current_action:
				G.ACTION.MOVE:
					move(event.relative)
				G.ACTION.RESIZE:
					resize(event.relative, resize_type)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if not focus:
					emit_signal("focus_requested", self)
				if current_action == G.ACTION.NONE:
					current_action = G.ACTION.MOVE
			else:
				current_action = G.ACTION.NONE


func move(p_relative : Vector2) -> void:
	position += p_relative
	synchronize()


func resize(p_relative : Vector2, p_type : G.RESIZE) -> void:
	if size.y == 0:
		return
	var aspect_ratio : float = size.x / size.y
	if keep_ratio:
		match p_type:
			G.RESIZE.RIGHT:
				size.x += p_relative.x
				size.y = size.x / aspect_ratio
			G.RESIZE.BOTTOM:
				size.y += p_relative.y
				size.x = size.y * aspect_ratio
			G.RESIZE.BOTH:
				size.x += p_relative.x
				size.y = size.x / aspect_ratio
			G.RESIZE.LEFT:
				size.x -= p_relative.x
				position.x += p_relative.x
				size.y = size.x / aspect_ratio
			G.RESIZE.TOP:
				size.y -= p_relative.y
				position.y += p_relative.y
				size.x = size.y * aspect_ratio
	else:
		match p_type:
			G.RESIZE.RIGHT:
				size.x += p_relative.x
			G.RESIZE.BOTTOM:
				size.y += p_relative.y
			G.RESIZE.BOTH:
				size += p_relative
			G.RESIZE.LEFT:
				size.x -= p_relative.x
				position.x += p_relative.x
			G.RESIZE.TOP:
				size.y -= p_relative.y
				position.y += p_relative.y
	synchronize()


func _on_resized() -> void:
	await get_tree().process_frame
	buttons.resize(size)


func set_clone(p_clone : Widget) -> void:
	clone = p_clone
	p_clone.add_theme_stylebox_override("panel", unfocus_theme)
	p_clone.buttons.hide()
	synchronize()


func is_master() -> bool:
	return is_instance_valid(clone)


func synchronize() -> void:
	if not is_master():
		return
	clone.set_position(position)
	clone.set_size(size)
	clone.visible = visible_on_presentation_screen


func _on_buttons_resize_pressed(p_resize_type : G.RESIZE, p_keep_ratio : bool = false) -> void:
	current_action = G.ACTION.RESIZE
	resize_type = p_resize_type
	keep_ratio = p_keep_ratio


func _on_buttons_toggle_visible_pressed() -> void:
	current_action = G.ACTION.TOGGLE_VISIBLE
	if is_master():
		if visible_on_presentation_screen:
			clone.hide()
			modulate.a = 0.3
			visible_on_presentation_screen = false
		else:
			clone.show()
			modulate.a = 1.0
			visible_on_presentation_screen = true


func _on_buttons_close_pressed() -> void:
	current_action = G.ACTION.CLOSE
	queue_free()
	if is_master():
		clone.queue_free()


func set_focus(p_active: bool) -> void:
	focus = p_active
	buttons.visible = p_active
	add_theme_stylebox_override("panel", focus_theme if p_active else unfocus_theme)
	mouse_filter = Control.MOUSE_FILTER_STOP if focus else Control.MOUSE_FILTER_IGNORE
	


func _on_buttons_duplicate_pressed():
	emit_signal("duplicate_requested", self)


func _on_buttons_locked_pressed():
	locked = !locked
	mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_DRAG


func _on_buttons_layer_down_pressed():
	emit_signal("layer_change_requested", self, -1)


func _on_buttons_layer_up_pressed():
	emit_signal("layer_change_requested", self, 1)
