extends Marker2D

signal resize_pressed(resize_type : G.RESIZE)
signal text_size_pressed(increment : int)
signal toggle_visible_pressed
signal close_pressed
signal text_color_changed(color : Color)
signal duplicate_pressed

@onready var resize_top : TextureButton = $ResizeTop
@onready var resize_bottom : TextureButton = $ResizeBottom
@onready var resize_left : TextureButton = $ResizeLeft
@onready var resize_right : TextureButton = $ResizeRight
@onready var resize_both : TextureButton = $ResizeBoth
@onready var rotate_button : TextureButton = $Rotate

@onready var panel : Panel = $Panel
@onready var top_buttons : HBoxContainer = $Panel/TopButtons
@onready var toggle_visible : TextureButton= $Panel/TopButtons/ToggleVisible

@onready var left_buttons : HBoxContainer = $LeftButtons

@onready var size_minus : TextureButton = $LeftButtons/SizeMinus
@onready var size_plus : TextureButton = $LeftButtons/SizePlus

@onready var text_color : TextureButton = $LeftButtons/TextColor
@onready var color_picker : HBoxContainer = $ColorPicker

@onready var color_buttons : Array[TextureButton] = [$ColorPicker/Black, $ColorPicker/Red, $ColorPicker/Green, $ColorPicker/Blue]

var border_width : int = 15
var border_thin_width : int = 4

var minimum_width_for_top_resize : int = 260

func _ready():
	panel.size.x = top_buttons.size.x + 20

#
# Reposition buttons when parent widget is resized
#
func resize(p_size : Vector2) -> void:
	resize_top.position = Vector2((p_size.x - border_thin_width) / 2.0 - 6, - 10)
	resize_bottom.position = Vector2((p_size.x - border_thin_width) / 2.0 - 6, p_size.y - 10)
	resize_left.position = Vector2(-10.0, (p_size.y - border_thin_width) / 2.0)
	resize_right.position = Vector2(p_size.x - border_thin_width - 6, (p_size.y - border_thin_width) / 2.0)
	resize_both.position = p_size - Vector2.ONE * border_thin_width - Vector2(10,10)
	rotate_button.position = Vector2(p_size.x - border_width, 0.0 ) + Vector2(-10,7)
	color_picker.position = text_color.position + left_buttons.position

	resize_top.visible = resize_top.position.x > panel.size.x
	
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

func hide_button_size():
	size_minus.hide()
	size_plus.hide()

func hide_button_color():
	color_picker.hide()
	text_color.hide()


func _on_duplicate_pressed():
	emit_signal("duplicate_pressed")
