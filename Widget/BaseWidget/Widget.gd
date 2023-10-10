extends PanelContainer
class_name Widget

signal focus_requested(widget : Widget)

@export var border_width : int = 20

@onready var buttons : Node2D = $Buttons

@onready var focus_theme : StyleBoxFlat = load("res://Styles/Widget_master_selected.tres")
@onready var unfocus_theme : StyleBoxFlat = load("res://Styles/Widget_unfocus.tres")

var focus : bool = true

var current_action : G.ACTION = G.ACTION.NONE
var resize_type : G.RESIZE = G.RESIZE.NONE

# Reference to the same widget on presentation screen
var clone : Widget = null


func _ready() -> void :
	_on_resized()


func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
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


func is_master() -> bool:
	return is_instance_valid(clone)


func synchronize() -> void:
	if not is_master():
		return
	clone.set_position(position)
	clone.set_size(size)


func _on_buttons_resize_pressed(p_resize_type : G.RESIZE) -> void:
	current_action = G.ACTION.RESIZE
	resize_type = p_resize_type


func _on_buttons_toggle_visible_pressed() -> void:
	current_action = G.ACTION.TOGGLE_VISIBLE
	if is_master():
		if clone.visible:
			clone.hide()
			modulate.a = 0.3
		else:
			clone.show()
			modulate.a = 1.0


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
	


