extends WidgetData
class_name TextWidgetData

@export var text : String = String()
@export var text_color : Color = Color.BLACK
@export var text_size : int = 12

func store(p_widget : Widget) -> void:
	var p_text_widget : TextWidget = p_widget as TextWidget
	text = p_text_widget.get_text()
	text_color = p_text_widget.get_text_color()
	text_size = p_text_widget.get_text_size()
	super(p_widget)

func setup_widget(p_widget : Widget) -> void:
	var p_text_widget : TextWidget = p_widget as TextWidget
	p_text_widget.set_text(text)
	p_text_widget.set_text_color(text_color)
	p_text_widget.set_text_size(text_size)
	super(p_widget)
	
func print_data() -> void:
	super()
	print("Text %s" % text)
	print("Text Color %s" % text_color)
	print("Text Size %s" % text_size)
