extends Marker2D

signal resize_pressed(resize_type : G.RESIZE)
signal text_size_pressed(increment : int)
signal rotate_pressed
signal toggle_visible_pressed
signal close_pressed
signal text_color_changed(color : Color)
signal duplicate_pressed
signal layer_down_pressed
signal layer_up_pressed
signal locked_pressed
signal editable_pressed
signal resizing_stopped
#region Nodes references

@onready var resize_top : TextureButton = $ResizeTop
@onready var resize_bottom : TextureButton = $ResizeBottom
@onready var resize_left : TextureButton = $ResizeLeft
@onready var resize_right : TextureButton = $ResizeRight
@onready var resize_both : TextureButton = $ResizeBoth
@onready var rotate_button : TextureButton = $Rotate

@onready var markers : Array[Marker2D] = [$Markers/Top, $Markers/TopRight,
											$Markers/Right, $Markers/BottomRight,
											$Markers/Bottom, $Markers/BottomLeft,
											$Markers/Left, $Markers/TopLeft,
											$Markers/Middle]

@onready var panel : Panel = $Panel
@onready var top_buttons : HBoxContainer = $Panel/TopButtons
@onready var toggle_visible : TextureButton= $Panel/TopButtons/ToggleVisible
@onready var lock_button : TextureButton = $Panel/TopButtons/Lock

@onready var left_buttons : HBoxContainer = $LeftButtons

@onready var size_minus : TextureButton = $LeftButtons/SizeMinus
@onready var size_plus : TextureButton = $LeftButtons/SizePlus

@onready var text_color : TextureButton = $LeftButtons/TextColor
@onready var color_picker : HBoxContainer = $ColorPicker

@onready var color_buttons : Array[TextureButton] = [$ColorPicker/Black, $ColorPicker/Red, $ColorPicker/Green, $ColorPicker/Blue]

#endregion

var border_width : int = 15
var border_thin_width : int = 4

var minimum_width_for_top_resize : int = 260

func _ready() -> void:
	panel.size.x = top_buttons.size.x + 20
	
#
# Reposition buttons when parent widget is resized
#
func update_positions(p_size : Vector2) -> void:
	update_markers_positions(p_size)
	update_buttons_positions(p_size)
	adjust_top_resize_button_visibility()

func update_buttons_positions(p_size : Vector2) -> void:
	resize_top.position = Vector2((p_size.x - border_thin_width) / 2.0 - 6, - 10)
	resize_bottom.position = Vector2((p_size.x - border_thin_width) / 2.0 - 6, p_size.y - 10)
	resize_left.position = Vector2(-10.0, (p_size.y - border_thin_width) / 2.0)
	resize_right.position = Vector2(p_size.x - border_thin_width - 6, (p_size.y - border_thin_width) / 2.0)
	resize_both.position = p_size - Vector2.ONE * border_thin_width - Vector2(10,10)
	rotate_button.position = Vector2(p_size.x - border_width, 0.0 ) + Vector2(-10,7)
	color_picker.position = text_color.position + left_buttons.position

func update_markers_positions(p_size : Vector2) -> void:
	markers[G.MARKER.TOP].position = Vector2(p_size.x / 2.0, 0.0)
	markers[G.MARKER.TOP_RIGHT].position = Vector2(p_size.x - 4, 30.0)
	markers[G.MARKER.RIGHT].position = Vector2(p_size.x, p_size.y / 2.0)
	markers[G.MARKER.BOTTOM_RIGHT].position = Vector2(p_size.x - 4, p_size.y - 4)
	markers[G.MARKER.BOTTOM].position = Vector2(p_size.x / 2.0, p_size.y)
	markers[G.MARKER.BOTTOM_LEFT].position = Vector2(4.0, p_size.y - 4.0)
	markers[G.MARKER.LEFT].position = Vector2(0.0, p_size.y / 2.0)
	markers[G.MARKER.TOP_LEFT].position = Vector2(4.0, 30.0)
	markers[G.MARKER.MIDDLE].position = p_size / 2.0

func adjust_top_resize_button_visibility() -> void:
	if not resize_both.visible:
		return
	var resize_top_visible : bool = resize_top.visible
	resize_top.visible = resize_top.position.x > panel.size.x
	if resize_top_visible and not resize_top.visible:
		emit_signal("resizing_stopped")
		
#region Follow button signals to parent widget
func _on_resize_top_button_down() -> void:
	emit_signal("resize_pressed", G.RESIZE.TOP)

func _on_resize_bottom_button_down() -> void:
	emit_signal("resize_pressed", G.RESIZE.BOTTOM)

func _on_resize_left_button_down() -> void:
	emit_signal("resize_pressed", G.RESIZE.LEFT)

func _on_resize_right_button_down() -> void:
	emit_signal("resize_pressed", G.RESIZE.RIGHT)

func _on_resize_both_button_down() -> void:
	emit_signal("resize_pressed", G.RESIZE.BOTH)

func _on_size_minus_button_down() -> void:
	emit_signal("text_size_pressed", -1)
	
func _on_size_plus_button_down() -> void:
	emit_signal("text_size_pressed", 1)

func _on_toggle_visible_button_down() -> void:
	emit_signal("toggle_visible_pressed")

func _on_close_button_down() -> void:
	emit_signal("close_pressed")

func _on_text_color_pressed() -> void:
	color_picker.show()

func _on_black_pressed() -> void:
	set_color(G.color[G.COLOR.BLACK], color_buttons[G.COLOR.BLACK])
	
func _on_blue_pressed() -> void:
	set_color(G.color[G.COLOR.BLUE], color_buttons[G.COLOR.BLUE])

func _on_green_pressed() -> void:
	set_color(G.color[G.COLOR.GREEN], color_buttons[G.COLOR.GREEN])

func _on_red_pressed() -> void:
	set_color(G.color[G.COLOR.RED], color_buttons[G.COLOR.RED])

func _on_duplicate_pressed() -> void:
	emit_signal("duplicate_pressed")

func _on_layer_up_pressed() -> void:
	emit_signal("layer_up_pressed")


func _on_layer_down_pressed() -> void:
	emit_signal("layer_down_pressed")


func _on_editable_pressed() -> void:
	emit_signal("editable_pressed")


func _on_lock_pressed() -> void:
	emit_signal("locked_pressed")
	for button : TextureButton in [resize_both, resize_bottom, resize_left, resize_right, resize_top, rotate_button]:
		button.visible = not lock_button.is_pressed()

#endregion

func set_color(p_color : Color, p_button : TextureButton = null) -> void:
	text_color.modulate = p_color
	# Move the color button at the first position
	if is_instance_valid(p_button):
		color_picker.move_child(p_button, 0)
	color_picker.hide()
	emit_signal("text_color_changed", p_color)
	
func get_color() -> Color:
	return text_color.modulate

func hide_button_size() -> void:
	size_minus.hide()
	size_plus.hide()

func hide_button_color() -> void:
	color_picker.hide()
	text_color.hide()
	
func hide_button_resize() -> void:
	resize_both.hide()
	resize_bottom.hide()
	resize_left.hide()
	resize_right.hide()
	resize_top.hide()
	
func _on_rotate_button_down() -> void:
	emit_signal("rotate_pressed")


func get_marker_position(p_marker : G.MARKER) -> Vector2:
	return markers[p_marker].global_position
