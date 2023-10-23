extends ItemList
class_name PreviewList

signal board_requested(index : int)
signal board_delete_requested(index : int)
signal board_duplicate_requested(index : int)

var item_hovered : int = -1

@onready var buttons_overlay = $ButtonsOverlay

func _on_item_selected(p_index):
	emit_signal("board_requested", p_index)


func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		var item = get_item_at_position(event.position)
		if item != item_hovered:
			update_button_overlay_position(item)

func update_button_overlay_position(p_item : int) -> void:
	item_hovered = p_item
	buttons_overlay.visible = item_hovered >= 0
	buttons_overlay.position = get_item_rect(item_hovered).position + Vector2(6.0 ,5.0)

func hide_overlay() -> void:
	item_hovered = -1
	buttons_overlay.hide()


func _on_delete_pressed():
	emit_signal("board_delete_requested", item_hovered)

func _on_duplicate_pressed():
	emit_signal("board_duplicate_requested", item_hovered)
