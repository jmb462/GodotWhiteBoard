extends Widget
class_name ImageWidget

@onready var texture_rect : TextureRect = $TextureRect

func _ready():
	buttons.hide_button_size()
	buttons.hide_button_color()

func set_clone(p_clone : Widget) -> void:
	super(p_clone)
	clone.texture_rect.texture = texture_rect.texture

func set_texture(p_image : Image) -> void:
	var texture = ImageTexture.create_from_image(p_image)
	texture_rect.texture = texture

func synchronize() -> void:
	if not is_master():
		return
	super()

func _on_resized() -> void:
	super()
	if not is_instance_valid(texture_rect):
		return
	if not is_instance_valid(texture_rect.texture):
		return
	pivot_offset = texture_rect.texture.get_size() / 2.0
	
func _on_texture_rect_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if not focus:
					emit_signal("focus_requested", self)

func set_focus(p_active: bool) -> void:
	super(p_active)

func _on_buttons_resize_pressed(p_resize_type : G.RESIZE, _p_keep_ratio : bool = true) -> void:
	super(p_resize_type, true)
