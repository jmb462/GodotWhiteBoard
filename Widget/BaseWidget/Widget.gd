extends PanelContainer
class_name Widget

signal widget_deleted(widget : Widget)
signal focus_requested(widget : Widget)
signal duplicate_requested(widget : Widget)
signal layer_change_requested(widget : Widget, direction : int, register_action : bool)
signal widget_changed

@onready var buttons : Node2D = $Buttons
@onready var focus_theme : StyleBoxFlat = load("res://Styles/Widget_master_selected.tres")
@onready var unfocus_theme : StyleBoxFlat = load("res://Styles/Widget_unfocus.tres")

var focus : bool = true
var visible_on_presentation_screen : bool = true

var decoration_size : Vector2 = Vector2(8.0, 34.0)

# A locked widget cannot be resized or moved
var locked : bool = false

var editable : bool = true

var current_action : G.ACTION = G.ACTION.NONE
var previous_action : G.ACTION = G.ACTION.NONE
var resize_type : G.RESIZE = G.RESIZE.NONE
var keep_ratio : bool = false

var pinned_marker : G.MARKER = G.MARKER.TOP_LEFT
var pinned_marker_position : Vector2 = Vector2.ZERO

# Reference to the same widget on presentation screen
var clone : Widget = null
var master : Widget = null

# Reference to the parent widget if grouped with other widget
var grouped_in : Widget = null

var start_rotation_degrees : float = 0.0
var start_rect : Rect2 = Rect2()

func get_type() -> String:
	return "Widget"

func _ready() -> void :
	_on_resized()
	emit_signal("widget_changed")


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
					if not locked:
						set_current_action(G.ACTION.MOVE)
			else:
				set_current_action(G.ACTION.NONE)

func set_current_action(p_action : G.ACTION) -> void:
	if current_action != p_action:
		print("switch from %s to %s" % [G.get_action_name(current_action), G.get_action_name(p_action)])
		previous_action = current_action
		current_action = p_action
		
		if p_action == G.ACTION.ROTATE:
			start_rotation_degrees = rotation_degrees
			
		if p_action == G.ACTION.MOVE or p_action == G.ACTION.RESIZE:
			start_rect = get_rect()
			print(start_rect)
		
		if previous_action == G.ACTION.ROTATE:
			if start_rotation_degrees != rotation_degrees:
				var new_rotation_action = ActionRotate.new()
				new_rotation_action.setup(self, start_rotation_degrees, rotation_degrees, pivot_offset)
				Undo.add_action(new_rotation_action)
			
		if previous_action == G.ACTION.MOVE or previous_action == G.ACTION.RESIZE:
			var current_rect = get_rect()
			if start_rect != current_rect:
				var new_rect_action = ActionRectChange.new()
				new_rect_action.setup(self, start_rect, current_rect)
				Undo.add_action(new_rect_action)

func move(p_relative : Vector2) -> void:
	position += p_relative
	emit_signal("widget_changed")	
	synchronize()


func resize(p_relative : Vector2, p_resize_type : G.RESIZE) -> void:
	if size.y == 0:
		return
	var aspect_ratio : float = size.x / size.y
	pin_marker(get_fix_marker(p_resize_type))
	var direction : float = -1.0 if p_resize_type in [G.RESIZE.LEFT, G.RESIZE.TOP] else 1.0
	match p_resize_type:
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
	emit_signal("widget_changed")	
	synchronize()


func rotate_widget(p_position : Vector2) -> void:
	buttons.update_markers_positions(size)
	var corner_angle : float = asin((size.y / 2.0) / buttons.get_marker_position(G.MARKER.MIDDLE).distance_to( buttons.get_marker_position(G.MARKER.TOP_RIGHT)))
	var new_angle : float = buttons.get_marker_position(G.MARKER.MIDDLE).angle_to_point(p_position) + corner_angle
	rotation = snap_angle(new_angle, PI / 2.0, PI / 36.0)
	emit_signal("widget_changed")	
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
	p_clone.master = self
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
	clone.z_index = z_index

func _on_buttons_resize_pressed(p_resize_type : G.RESIZE, p_keep_ratio : bool = false) -> void:
	set_current_action(G.ACTION.RESIZE)
	resize_type = p_resize_type
	keep_ratio = p_keep_ratio


func _on_buttons_toggle_visible_pressed(p_register_action : bool = true) -> void:
	toggle_visibility()
	if p_register_action:
		var new_visibility_action = ActionVisibility.new()
		new_visibility_action.setup(self)
		Undo.add_action(new_visibility_action)
	
func toggle_visibility() -> void:
	set_current_action(G.ACTION.TOGGLE_VISIBLE)
	if is_master():
		if visible_on_presentation_screen:
			clone.hide()
			modulate.a = 0.3
			visible_on_presentation_screen = false
		else:
			clone.show()
			modulate.a = 1.0
			visible_on_presentation_screen = true
	emit_signal("widget_changed")

func _on_buttons_close_pressed() -> void:
	set_current_action(G.ACTION.CLOSE)
	delete()

func delete() -> void:
	emit_signal("widget_deleted", self)
	queue_free()
	if is_master():
		clone.queue_free()

func set_focus(p_active: bool) -> void:
	focus = p_active
	buttons.visible = p_active
	self_modulate.a = 1.0 if p_active else 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP if focus else Control.MOUSE_FILTER_IGNORE
	


func _on_buttons_duplicate_pressed() -> void:
	emit_signal("duplicate_requested", self)


func _on_buttons_locked_pressed(p_register_action : bool = true) ->  void:
	toggle_lock()
	if p_register_action:
		var new_lock_action = ActionLock.new()
		new_lock_action.setup(self)
		Undo.add_action(new_lock_action)

func toggle_lock() -> void:
	locked = !locked
	mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_DRAG

	
func _on_buttons_layer_down_pressed() -> void:
	emit_signal("layer_change_requested", self, -1)


func _on_buttons_layer_up_pressed() -> void:
	emit_signal("layer_change_requested", self, 1)


func _on_buttons_rotate_pressed() -> void:
	set_current_action(G.ACTION.ROTATE)
	buttons.update_markers_positions(size)
	pin_marker(G.MARKER.MIDDLE)
	set_pivot(size / 2.0)	
	move_to_pin()
	buttons.update_markers_positions(size)


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
func _on_buttons_resizing_stopped() -> void:
	if current_action == G.ACTION.RESIZE and resize_type == G.RESIZE.TOP:
		set_current_action(G.ACTION.NONE)

func get_marker_position(p_marker : G.MARKER) -> Vector2:
	return buttons.get_marker_position(p_marker)

func group_into(p_widget : Widget) -> void:
	grouped_in = p_widget
	mouse_filter = MOUSE_FILTER_IGNORE

## Returns a WidgetData resource with persistant data of the widget.
func get_data() -> WidgetData:
	var widget_data : WidgetData = WidgetData.new()
	widget_data.store(self)
	return widget_data
