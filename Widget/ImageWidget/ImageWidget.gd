extends Widget
class_name ImageWidget

## Unique ID used to save image resource
var image_uid : int = 0

@onready var texture_rect : TextureRect = $Anchor/TextureRect

func _ready() -> void:
	buttons.hide_button_size()
	buttons.hide_button_color()
	size = texture_rect.size + decoration_size
	image_uid = ResourceUID.create_id()
	
	
func get_type() -> String:
	return "ImageWidget"

func set_clone(p_clone : Widget) -> void:
	super(p_clone)
	clone.texture_rect.texture = texture_rect.texture

func set_texture(p_image : Image) -> void:
	var texture : ImageTexture = ImageTexture.create_from_image(p_image)
	texture_rect.size = p_image.get_size()
	texture_rect.texture = texture
	size = texture_rect.size + decoration_size

func get_texture() -> Texture2D:
	return texture_rect.texture

func get_image_size() -> Vector2:
	return texture_rect.size

func synchronize() -> void:
	if not is_master():
		return
	clone.texture_rect.size = texture_rect.size
	super()

func _on_resized() -> void:
	super()
	if not is_instance_valid(texture_rect):
		return
	if not is_instance_valid(texture_rect.texture):
		return
	
	size = texture_rect.size + decoration_size
	pivot_offset = texture_rect.texture.get_size() / 2.0

func resize(p_relative : Vector2, p_resize_type : G.RESIZE) -> void:
	pin_marker(get_fix_marker(p_resize_type))
	
	var aspect_ratio : float = texture_rect.size.x / texture_rect.size.y
	var direction : float = -1.0 if p_resize_type in [G.RESIZE.LEFT, G.RESIZE.TOP] else 1.0
	match p_resize_type:
		G.RESIZE.RIGHT, G.RESIZE.LEFT:
			var new_size : float = texture_rect.size.x + (p_relative.x * direction)
			texture_rect.size = Vector2(new_size, (new_size / aspect_ratio) if keep_ratio else texture_rect.size.y)
		G.RESIZE.BOTTOM, G.RESIZE.TOP:
			var new_size : float = texture_rect.size.y + (p_relative.y * direction)
			texture_rect.size = Vector2((new_size * aspect_ratio) if keep_ratio else texture_rect.size.x, new_size)
		G.RESIZE.BOTH:
			var new_size : float = texture_rect.size.x + (p_relative.x * direction)
			texture_rect.size = Vector2(new_size, (new_size / aspect_ratio) if keep_ratio else texture_rect.size.y + p_relative.y)
	
	size = texture_rect.size + decoration_size

	buttons.update_positions(size)
	move_to_pin()
	synchronize()
	
	#super(p_relative, p_resize_type)

func _on_texture_rect_gui_input(p_event : InputEvent) -> void:
	if p_event is InputEventMouseButton:
		if p_event.button_index == MOUSE_BUTTON_LEFT:
			if p_event.is_pressed():
				if not focus:
					emit_signal("focus_requested", self)

func set_focus(p_active: bool) -> void:
	super(p_active)

func _on_buttons_resize_pressed(p_resize_type : G.RESIZE, _p_keep_ratio : bool = true) -> void:
	super(p_resize_type, true)
