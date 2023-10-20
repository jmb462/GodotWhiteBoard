extends PanelContainer
class_name Widget

signal widget_deleted(widget : Widget)
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

var pinned_marker : G.MARKER = G.MARKER.TOP_LEFT
var pinned_marker_position : Vector2 = Vector2.ZERO

# Reference to the same widget on presentation screen
var clone : Widget = null

# Reference to the parent widget if grouped with other widget
var grouped_in : Widget = null

func _ready() -> void :
	_on_resized()

func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not locked:
			match current_action:
				G.ACTION.MOVE:
					move(event.relative.rotated(rotation))
				G.ACTION.RESIZE:
						resize(event.relative, resize_type)
				G.ACTION.ROTATE:
					rotate_widget(event.global_position)

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


func resize(p_relative : Vector2, p_rotation_type : G.RESIZE) -> void:
	if size.y == 0:
		return
	var aspect_ratio : float = size.x / size.y
	pin_marker(get_fix_marker(p_rotation_type))
	var direction : float = -1.0 if p_rotation_type in [G.RESIZE.LEFT, G.RESIZE.TOP] else 1.0
	match p_rotation_type:
		G.RESIZE.RIGHT, G.RESIZE.LEFT:
			var new_size : float = size.x + (p_relative.x * direction)
			size = Vector2(new_size, (new_size / aspect_ratio) if keep_ratio else size.y)
		G.RESIZE.BOTTOM, G.RESIZE.TOP:
			var new_size : float = size.y + (p_relative.y * direction)
			size = Vector2((new_size * aspect_ratio) if keep_ratio else size.x, new_size)
		G.RESIZE.BOTH:
			var new_size : float = size.x + (p_relative.x * direction)
			size = Vector2(new_size, (new_size / aspect_ratio) if keep_ratio else size.y + p_relative.y)
	buttons.update_positions(size)
	move_to_pin()
	synchronize()

func rotate_widget(p_position : Vector2) -> void:
	buttons.update_markers_positions(size)
	var corner_angle : float = asin((size.y / 2.0) / buttons.get_marker_position(G.MARKER.MIDDLE).distance_to( buttons.get_marker_position(G.MARKER.TOP_RIGHT)))
	var new_angle : float = buttons.get_marker_position(G.MARKER.MIDDLE).angle_to_point(p_position) + corner_angle
	rotation = snap_angle(new_angle, PI / 2.0, PI / 36.0)
	synchronize()

func snap_angle(angle_rad : float , p_multiple : float, p_threshold : float) -> float:
	var nearest_multiple : float = round(angle_rad / p_multiple) * p_multiple
	if abs(angle_rad - nearest_multiple) <= p_threshold:
		return nearest_multiple
	else:
		return angle_rad

func _on_resized() -> void:
	if not is_instance_valid(buttons):
		return
	buttons.update_positions(size)


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
	clone.pivot_offset = pivot_offset
	clone.rotation = rotation
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
	emit_signal("widget_deleted", self)
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


func _on_buttons_rotate_pressed():
	current_action = G.ACTION.ROTATE
	buttons.update_markers_positions(size)
	pin_marker(G.MARKER.MIDDLE)
	set_pivot(size / 2.0)	
	move_to_pin()
	buttons.update_markers_positions(size)
	G.debug_action(current_action)

#
# Set pivot point and update middle marker
#
func set_pivot(p_position : Vector2) -> void:
		pivot_offset = p_position
		buttons.update_positions(size)

#
# Return the marker used as fix point while resizing
#
func get_fix_marker(p_resize_type : G.RESIZE) -> G.MARKER:
	match p_resize_type:
		G.RESIZE.RIGHT, G.RESIZE.BOTH, G.RESIZE.BOTTOM:
			return G.MARKER.TOP_LEFT
		G.RESIZE.LEFT:
			return G.MARKER.TOP_RIGHT
		G.RESIZE.TOP:
			return G.MARKER.BOTTOM_LEFT
		_:
			return G.MARKER.MIDDLE
	
#
# Store global position of chosen marker
#
func pin_marker(p_marker : G.MARKER) -> void:
	pinned_marker = p_marker
	pinned_marker_position = get_marker_position(p_marker)
#
# Restore the pinned position
#
func move_to_pin() -> void:
	position -= get_marker_position(pinned_marker) - pinned_marker_position

#
# Stop resizing when cannot use top grabber anymore
# because widget is too small
#
func _on_buttons_resizing_stopped():
	if current_action == G.ACTION.RESIZE and resize_type == G.RESIZE.TOP:
		current_action = G.ACTION.NONE

func get_marker_position(p_marker : G.MARKER) -> Vector2:
	return buttons.get_marker_position(p_marker)

func group_into(p_widget) -> void:
	grouped_in = p_widget
	mouse_filter = MOUSE_FILTER_IGNORE
