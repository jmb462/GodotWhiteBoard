extends WidgetData
class_name ImageWidgetData

@export var texture : Texture2D = null
@export var image_size : Vector2 = Vector2()
@export var image_uid : int = 0

func store(p_widget : Widget) -> void:
	var p_image_widget : ImageWidget = p_widget as ImageWidget
	image_size = p_image_widget.get_image_size()
	image_uid = p_image_widget.image_uid
	p_image_widget.get_texture().get_image().save_png("user://%s.png"%image_uid)

func setup_widget(p_widget : Widget) -> void:
	var p_image_widget : ImageWidget = p_widget as ImageWidget
	p_image_widget.set_image_size(image_size)
	p_image_widget.image_uid = image_uid
	var image : Image = load("user://%s.png"%image_uid)
	p_image_widget.set_texture(image)
	super(p_widget)

func print_data() -> void:
	super()
	print("Image size %s" % image_size)
	print("Image Unique ID %s" % image_uid)
