extends PanelContainer
class_name Widget

signal focus_requested(widget : Widget)

@export var border_width : int = 20
@export var text_size_increment : int = 3

@onready var buttons : Node2D = $Buttons
@onready var text_edit : TextEdit = $TextEdit

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

func _on_text_edit_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if not focus:
					emit_signal("focus_requested", self)

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


func change_text_size(p_increment : int) -> void:
	set_text_size(max(get_text_size() + p_increment, 8))
	synchronize()


func autozoom() -> void:
	while text_edit.get_v_scroll_bar().is_visible_in_tree() and text_edit.get_theme_font_size("font_size") > 8:
		change_text_size(-1)
		await get_tree().process_frame


func _on_text_edit_text_changed() -> void:
	if text_edit.get_v_scroll_bar().is_visible_in_tree():
		autozoom()
	synchronize()


func set_clone(p_clone : Widget) -> void:
	clone = p_clone
	p_clone.add_theme_stylebox_override("panel", unfocus_theme)
	p_clone.text_edit.placeholder_text = ""
	p_clone.buttons.hide()


func is_master() -> bool:
	return is_instance_valid(clone)

func synchronize() -> void:
	if not is_master():
		return
	clone.set_position(position)
	clone.set_size(size)
	clone.set_text(get_text())
	clone.set_text_color(get_text_color())
	clone.set_text_size(get_text_size())


func get_text() -> String:
	return text_edit.get_text()


func set_text(p_text : String) -> void:
	text_edit.set_text(p_text)


func get_text_color() -> Color:
	return text_edit.get_theme_color("font_color")


func set_text_color(p_color : Color) -> void:
	text_edit.add_theme_color_override("font_color", p_color)


func get_text_size() -> int:
	return text_edit.get_theme_font_size("font_size")


func set_text_size(p_size : int) -> void:
	text_edit.add_theme_font_size_override("font_size", p_size)


func _on_buttons_resize_pressed(p_resize_type : G.RESIZE) -> void:
	current_action = G.ACTION.RESIZE
	resize_type = p_resize_type


func _on_buttons_text_size_pressed(p_increment : int) -> void:
	current_action = G.ACTION.TEXT_SIZE
	change_text_size(p_increment * text_size_increment)


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


func _on_buttons_text_color_changed(p_color : Color) -> void:
	current_action = G.ACTION.NONE
	set_text_color(p_color)
	synchronize()
	
func set_focus(p_active: bool) -> void:
	focus = p_active
	buttons.visible = p_active
	add_theme_stylebox_override("panel", focus_theme if p_active else unfocus_theme)
	mouse_filter = Control.MOUSE_FILTER_STOP if focus else Control.MOUSE_FILTER_IGNORE
	


