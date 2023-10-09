extends Marker2D

signal resize_pressed(resize_type : G.RESIZE)
signal text_size_pressed(increment : int)
signal toggle_visible_pressed
signal close_pressed
signal text_color_changed(color : Color)

@onready var resize_top : TextureButton = $ResizeTop
@onready var resize_bottom : TextureButton = $ResizeBottom
@onready var resize_left : TextureButton = $ResizeLeft
@onready var resize_right : TextureButton = $ResizeRight
@onready var resize_both : TextureButton = $ResizeBoth

@onready var left_buttons : HBoxContainer = $LeftButtons

@onready var size_minus : TextureButton = $LeftButtons/SizeMinus
@onready var size_plus : TextureButton = $LeftButtons/SizePlus
@onready var toggle_visible : TextureButton= $LeftButtons/ToggleVisible
@onready var text_color : TextureButton = $LeftButtons/TextColor
@onready var color_picker : HBoxContainer = $ColorPicker

@onready var color_buttons : Array[TextureButton] = [$ColorPicker/Black, $ColorPicker/Red, $ColorPicker/Green, $ColorPicker/Blue]

@onready var close : TextureButton = $Close

var border_width : int = 20
var minimum_width_for_top_resize : int = 260

#
# Reposition buttons when parent widget is resized
#
func resize(p_size : Vector2) -> void:
	resize_top.position = Vector2((p_size.x - border_width) / 2.0 , 0.0)
	resize_bottom.position = Vector2((p_size.x - border_width) / 2.0, p_size.y - border_width)
	resize_left.position = Vector2(0.0, (p_size.y - border_width) / 2.0)
	resize_right.position = Vector2(p_size.x - border_width, (p_size.y - border_width) / 2.0)
	resize_both.position = p_size - Vector2.ONE * border_width
	
	close.position = Vector2(p_size.x - 2.0 * border_width, 0.0)
	color_picker.position = text_color.position + left_buttons.position

	resize_top.visible = p_size.x > minimum_width_for_top_resize
	
func _on_resize_top_button_down():
	emit_signal("resize_pressed", G.RESIZE.TOP)

func _on_resize_bottom_button_down():
	emit_signal("resize_pressed", G.RESIZE.BOTTOM)

func _on_resize_left_button_down():
	emit_signal("resize_pressed", G.RESIZE.LEFT)

func _on_resize_right_button_down():
	emit_signal("resize_pressed", G.RESIZE.RIGHT)

func _on_resize_both_button_down():
	emit_signal("resize_pressed", G.RESIZE.BOTH)

func _on_size_minus_button_down():
	emit_signal("text_size_pressed", -1)
	
func _on_size_plus_button_down():
	emit_signal("text_size_pressed", 1)

func _on_toggle_visible_button_down():
	emit_signal("toggle_visible_pressed")

func _on_close_button_down():
	emit_signal("close_pressed")

func _on_text_color_pressed():
	color_picker.show()

func _on_black_pressed():
	set_color(G.color[G.COLOR.BLACK], color_buttons[G.COLOR.BLACK])
	
func _on_blue_pressed():
	set_color(G.color[G.COLOR.BLUE], color_buttons[G.COLOR.BLUE])

func _on_green_pressed():
	set_color(G.color[G.COLOR.GREEN], color_buttons[G.COLOR.GREEN])

func _on_red_pressed():
	set_color(G.color[G.COLOR.RED], color_buttons[G.COLOR.RED])

func set_color(p_color : Color, p_button : TextureButton = null) -> void:
	text_color.modulate = p_color
	# Move the color button at the first position
	if is_instance_valid(p_button):
		color_picker.move_child(p_button, 0)
	color_picker.hide()
	emit_signal("text_color_changed", p_color)
	
func get_color() -> Color:
	return text_color.modulate
