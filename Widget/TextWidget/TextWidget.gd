extends Widget
class_name TextWidget

@export var text_size_increment : int = 3

@onready var text_edit : TextEdit = $TextEdit


func _ready():
	set_focus(true)

func set_clone(p_clone : Widget) -> void:
	super(p_clone)
	p_clone.text_edit.placeholder_text = ""
	p_clone.text_edit.editable = false

func synchronize() -> void:
	if not is_master():
		return
	super()
	clone.set_text(get_text())
	clone.set_text_color(get_text_color())
	clone.set_text_size(get_text_size())

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

func _on_text_edit_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if not focus:
					text_edit.editable = true
					text_edit.grab_focus()
					emit_signal("focus_requested", self)


func get_text() -> String:
	return text_edit.get_text()


func set_text(p_text : String) -> void:
	text_edit.set_text(p_text)


func get_text_color() -> Color:
	return text_edit.get_theme_color("font_color")


func set_text_color(p_color : Color) -> void:
	text_edit.add_theme_color_override("font_color", p_color)
	text_edit.add_theme_color_override("font_readonly_color", p_color)

func get_text_size() -> int:
	return text_edit.get_theme_font_size("font_size")


func set_text_size(p_size : int) -> void:
	text_edit.add_theme_font_size_override("font_size", p_size)


func _on_buttons_text_color_changed(p_color : Color) -> void:
	current_action = G.ACTION.NONE
	set_text_color(p_color)
	synchronize()

func _on_buttons_text_size_pressed(p_increment : int) -> void:
	current_action = G.ACTION.TEXT_SIZE
	change_text_size(p_increment * text_size_increment)

func set_focus(p_active: bool) -> void:
	super(p_active)
	text_edit.editable = p_active and editable
	text_edit.grab_focus()

func _on_buttons_resize_pressed(p_resize_type : G.RESIZE, _p_keep_ratio : bool = false) -> void:
	super(p_resize_type)


func _on_buttons_editable_pressed():
	text_edit.editable = !text_edit.editable
	editable = text_edit.editable
