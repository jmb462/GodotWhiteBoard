extends Tree
class_name PreviewList

signal board_requested(index : int)
signal board_delete_requested(index : int)
signal board_duplicate_requested(index : int)

signal board_move(index : int, to_index : int)

var overlay_position : int = -1
var tree_items : Array[TreeItem] = []

var antispam_delay : float = 0.5
var antispam_activated : bool = false

@onready var buttons_overlay = $ButtonsOverlay

func _on_item_selected():
	emit_signal("board_requested", get_selected().get_index())


func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		var item = get_item_at_position(event.position)
		if not is_instance_valid(item):
			hide_overlay()
			return
		if item.get_index() != overlay_position:
			update_button_overlay_position(item)

func update_button_overlay_position(p_item : TreeItem) -> void:
	buttons_overlay.visible = is_instance_valid(p_item)
	buttons_overlay.position = get_item_area_rect(p_item).position + Vector2(6.0 ,6.0) - get_scroll()
	overlay_position = p_item.get_index()

func hide_overlay() -> void:
	overlay_position = -1
	buttons_overlay.hide()

func _on_delete_pressed() -> void:
	emit_signal("board_delete_requested", overlay_position)

func _on_duplicate_pressed() -> void:
	Debug.add("overlay_position", overlay_position)
	if antispam_activated:
		print("antispammed")
		return
	emit_signal("board_duplicate_requested", overlay_position)
	antispam_activated = true
	await get_tree().create_timer(antispam_delay).timeout
	antispam_activated = false
	
func update_tree(p_boards : Array[Board]) -> void:
	print("tree updated")
	clear()
	tree_items.clear()
	var root : TreeItem = create_item()
	for board : Board in p_boards:
		var item = create_item(root)
		tree_items.append(item)
		var viewport_texture : ViewportTexture = ViewportTexture.new()
		viewport_texture = board.viewport.get_texture()
		item.set_icon(0, viewport_texture)


func _on_mouse_exited() -> void:
	hide_overlay()

func select(p_index : int) -> void:
	if p_index >= tree_items.size():
		return
	set_selected(tree_items[p_index], 0)
	scroll_to_item(tree_items[p_index])
	queue_redraw()

func _get_drag_data(position): # begin drag
	set_drop_mode_flags(DROP_MODE_INBETWEEN)

	var preview = TextureRect.new()
	preview.texture = get_selected().get_icon(0)
	preview.scale *= 0.1
	set_drag_preview(preview) # not necessary

	return get_selected().get_index() # TreeItem


func _can_drop_data(position, data):
	return data is int # you shall not pass!


func _drop_data(position, from): # end drag
	var to_item = get_item_at_position(position)
	if not is_instance_valid(to_item):
		return
	var to_item_index = to_item.get_index()
	var shift = get_drop_section_at_position(position)

	var destination = to_item_index if shift < 0 else to_item_index + 1
	
	if from == destination or destination == from + 1:
		return 
	emit_signal('board_move', from, destination)
