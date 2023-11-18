extends HBoxContainer
class_name SortTree

signal sort_changed(p_filter : TREE_FILTER, p_inverted : bool)

enum TREE_FILTER { NAME, CREATED, MODIFIED }

@onready var filter_option : OptionButton = $FilterOption
@onready var invert_order_button : Button = $InvertOrderButton

@onready var NORMAL_FILTER_ICON : Texture2D = preload("res://Assets/Buttons/sort_up.png")
@onready var INVERTED_FILTER_ICON : Texture2D = preload("res://Assets/Buttons/sort_down.png")

var inverted : bool = false
var filter: TREE_FILTER = TREE_FILTER.NAME

func _ready() -> void:
	populate_filter_options()


func populate_filter_options() -> void:
	filter_option.add_item("Alphabetic Order")
	filter_option.add_item("Creation Date")
	filter_option.add_item("Last modification")	


func _on_invert_order_button_pressed() -> void:
	if inverted:
		invert_order_button.icon = NORMAL_FILTER_ICON
	else:
		invert_order_button.icon = INVERTED_FILTER_ICON
	inverted = not inverted
	emit_signal("sort_changed", filter, inverted)

func _on_filter_option_item_selected(p_index : int) -> void:
	filter = p_index as TREE_FILTER
	emit_signal("sort_changed", filter, inverted)
