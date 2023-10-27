extends Sprite2D
class_name AnimatedItem

#region Signal declarations

signal selected(index : int)
signal grabbed(index : int)
signal dropped(index : int)
signal mouse_entered(index : int)
signal mouse_exited(index : int)
signal delete_requested(index : int)
signal duplicate_requested(index : int)
signal scroll_requested(button : MouseButton)
#endregion

enum Z { NORMAL, UNDER, GRABBED}

func _process(_delta):
	$Debug.text = str(index)

#region Node references

@onready var preview : Sprite2D = $Preview
@onready var mouse_detection : Control = $MouseDetection
@onready var selected_overlay : Panel = $selected
@onready var buttons_overlay : Node2D = $ButtonsOverlay
@onready var delete_button : TextureButton = $ButtonsOverlay/Delete
@onready var duplicate_button : TextureButton = $ButtonsOverlay/Duplicate
#endregion

@export_category("Overlays")
@export var buttons_overlay_offset : Vector2 = Vector2(4.0 ,4.0)
@export var selected_border_width : Vector2 = Vector2(4.0, 4.0)
@export_category("Animations")
@export var grab_sensitivity : float = 5.0
@export var grab_scale_factor : float = 1.2
@export var tween_scale_duration : float = 0.05
@export var buttons_max_opacity : float = 0.35
@export var buttons_fade_in_duration : float = 0.05
@export var buttons_fade_out_duration : float = 0.05
@export var hover_scale_factor : float = 1.05
@export var tween_delete_duration : float = 0.2

var index : int = 0

var preview_scale : float = 1.0

# Temporary index used during dragging an item
var temp_index : int = 0

var grab_start_position : Vector2 = Vector2.ZERO
var is_grabbing : bool = false
var grab_start_x : float = 0.0
var grab_start_y_offset : float = 0.0

var is_left_mouse_down : bool = false
var is_mouse_over_buttons : bool = false

func _ready() -> void:
	return

func set_item_texture(p_texture):
	preview.set_texture(p_texture)
	var image : Image = Image.create(int(p_texture.get_size().x * preview_scale), int(p_texture.get_size().y  * preview_scale), false, Image.FORMAT_RGB8)
	texture = ImageTexture.create_from_image(image)
	resize()

func get_item_texture() -> Texture:
	return preview.texture

func get_size() -> Vector2:
	return texture.get_size()

func set_preview_scale(p_scale : float) -> void:
	preview_scale = p_scale
	preview.scale = Vector2.ONE * p_scale

func resize() -> void:
	mouse_detection.size = texture.get_size()
	mouse_detection.position = - texture.get_size() / 2.0
	buttons_overlay.position = - texture.get_size() / 2.0 + buttons_overlay_offset
	selected_overlay.size = mouse_detection.size - Vector2(4,0)
	selected_overlay.position = mouse_detection.position - Vector2(2,2)
	
func set_indexes(p_index : int) -> void:
	index = p_index
	temp_index = p_index


func select(p_active : bool) -> void:
	selected_overlay.visible = p_active


func is_selected() -> bool:
	return selected_overlay.visible

func freeze_texture():
	var freezed_image : Image = preview.texture.get_image()
	var freezed_texture : ImageTexture = ImageTexture.create_from_image(freezed_image)
	preview.texture = freezed_texture

func set_z(p_z : Z) -> void:
	preview.z_index = p_z
	selected_overlay.z_index = p_z

func get_z() -> int:
	return preview.z_index

#region Mouse inputs

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_left_mouse_down and is_grabbing:
				is_grabbing = false
				top_level = false
				mouse_detection.mouse_default_cursor_shape=Control.CURSOR_ARROW
				position.x = grab_start_x
				position.y -= grab_start_y_offset
				emit_signal("dropped", index)
				launch_tween_scale(false)
				is_left_mouse_down = false
				set_z(Z.NORMAL)
			if not event.is_pressed():
				is_left_mouse_down = false
	
func _on_mouse_detection_gui_input(p_event : InputEvent):
	if p_event is InputEventMouseButton:
		if is_left_mouse_click(p_event):
			is_left_mouse_down = p_event.is_pressed()
			if is_left_mouse_down and not is_mouse_over_buttons:
				grab_start_position = p_event.position
				emit_signal("selected", index)
		if p_event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			emit_signal("scroll_requested", p_event.button_index)
					
	if p_event is InputEventMouseMotion:
		if not is_grabbing and is_left_mouse_down:
			if p_event.position.distance_to(grab_start_position) > grab_sensitivity:
				emit_signal("grabbed", index)
				grab_start_x = position.x
				var local_y = position.y
				position = global_position
				grab_start_y_offset = position.y - local_y
				print(grab_start_y_offset)
				top_level = true
				is_grabbing = true
				mouse_detection.mouse_default_cursor_shape = Control.CURSOR_VSIZE
				
				launch_tween_scale(true)

func is_left_mouse_click(p_event : InputEvent, p_pressed : bool = true) -> bool:
	if not p_event is InputEventMouseButton:
		return false
	if not p_event.button_index == MOUSE_BUTTON_LEFT:
		return false
	if p_event.is_pressed() != p_pressed:
		return false
	return true
	

#endregion

#region Signal callbacks

func _on_mouse_detection_mouse_entered():
	emit_signal("mouse_entered", index)
	if get_z() != 2:
		launch_tween_over(true)

func _on_mouse_detection_mouse_exited():
	# Wait a frame to prevent mouse exit while hovering buttons
	#await get_tree().process_frame
	if not is_mouse_in_item():
		emit_signal("mouse_exited", index)
		launch_tween_over(false)

func is_mouse_in_item() -> bool:
	var item_rect : Rect2 = Rect2(Vector2.ZERO, get_size())
	var mouse_position = get_local_mouse_position() + get_size() / 2.0
	return item_rect.has_point(mouse_position)
	

func _on_delete_pressed() -> void:
	# Prevent buttons action if hidden
	if buttons_overlay.modulate.a < 0.02:
		return
	emit_signal("delete_requested", index)


func _on_duplicate_pressed() -> void:
	# Prevent buttons action if hidden
	if buttons_overlay.modulate.a < 0.02:
		return
	emit_signal("duplicate_requested", index)

func _on_buttons_mouse_over(p_over : bool) -> void:
	is_mouse_over_buttons = p_over
#endregion

#region Tweens

func launch_tween_scale(p_active : bool) -> void:
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * grab_scale_factor if p_active else Vector2.ONE, tween_scale_duration)


func launch_tween_over(p_active : bool) -> void:
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(buttons_overlay, "modulate:a", buttons_max_opacity if p_active else 0.0, buttons_fade_in_duration if p_active else buttons_fade_out_duration)
	tween.tween_property(self, "scale", Vector2.ONE * hover_scale_factor if p_active else Vector2.ONE, buttons_fade_in_duration * 2.0 if p_active else buttons_fade_out_duration * 2.0)


func launch_delete_tween() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 0.2, tween_delete_duration)
	tween.parallel().tween_property(self, "rotation_degrees", 180, tween_delete_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.8, tween_delete_duration)
	await tween.finished
	queue_free()
#endregion

func force_mouse_exit() -> void:
	if not is_mouse_in_item():
		launch_tween_over(false)

func get_grab_y() -> float:
	return position.y - grab_start_y_offset
