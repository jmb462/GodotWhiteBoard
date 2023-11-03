extends WidgetData
class_name ImageWidgetData

@export var texture : Texture2D = null
@export var image_size : Vector2 = Vector2()
@export var image_uid : int = 0

## Store persistant properties of the widget in the ImageWidgetData resource.
func store(p_widget : Widget) -> void:
	var p_image_widget : ImageWidget = p_widget as ImageWidget
	image_size = p_image_widget.get_image_size()
	image_uid = p_image_widget.image_uid
	if is_instance_valid(p_image_widget.get_texture()):
		p_image_widget.get_texture().get_image().save_png(get_image_path())
	super(p_widget)
	
## Restore persistant properties of the widget from the ImageWidgetData resource.
func restore(p_widget : Widget) -> void:
	super(p_widget)
	var p_image_widget : ImageWidget = p_widget as ImageWidget
	var image : Image = Image.new()
	image.load(get_image_path())
	p_image_widget.set_texture(image)
	p_image_widget.set_image_size(image_size)
	p_image_widget.image_uid = image_uid

func get_image_path() -> String:
	return G.document_path + "/%s.png" % image_uid

func print_data() -> void:
	super()
	print("Image size %s" % image_size)
	print("Image Unique ID %s" % image_uid)
