extends PanelContainer
class_name AnimatedList

#region Signals definition
signal item_selected(index : int)
signal item_moved(from : int, to : int)
signal item_mouse_entered(index : int)
signal item_mouse_exited(index : int)
signal item_delete_requested(index : int)
signal item_duplicate_requested(index : int)
#endregion

@export var vertical_separation : int = 10
@export var item_max_size_horizontal : int = 184

var items : Array[AnimatedItem]
var selected_item : AnimatedItem = null
var grabbed_item_index : int = -1

# Vertical size of all items with vertical separation
var real_size_y : float = 0.0

# All theses signals should be connected at item creation
var signals = ["selected","grabbed","dropped","mouse_exited","mouse_entered", "delete_requested", "duplicate_requested"]

# Used to center items horizontally into container
var items_horizontal_offset = 0

var preview_scale : float = 1.0

@onready var packed_item : PackedScene = preload("res://AnimatedList/AnimatedItem/AnimatedItem.tscn")

@onready var last_mouse_position : Vector2 = get_local_mouse_position()

@onready var scrollbar : VScrollBar = $VScrollBar
@onready var item_container : Node2D = $ItemsContainer

func _ready():
	pass


func create_item(p_index : int, p_texture : Texture2D = null) -> AnimatedItem:
	var item : AnimatedItem = packed_item.instantiate()
	item_container.add_child(item)
	item.set_preview_scale(preview_scale)
	if is_instance_valid(p_texture):
		item.set_item_texture(p_texture)
	item.position = get_item_position(p_index)
	items.insert(p_index, item)
	connect_all(item)	
	reposition_after_insert(item)
	for i in items.size():
		items[i].set_indexes(i)
	autosize()
	return item

func autosize() -> void:
	if items.size() == 0:
		return
	size.x = (item_max_size_horizontal + 2 * vertical_separation)
	real_size_y = (get_item_vertical() + vertical_separation) * (items.size()) + vertical_separation
	items_horizontal_offset = size.x / 2.0
	for item in items:
		item.position.x = items_horizontal_offset
	show_scroll_bar(size.y < real_size_y)

func get_item_vertical() -> float:
	if items.size() > 0:
		return items[0].get_size().y
	return 0.0

func get_item_position(p_index : int) -> Vector2:
	var item_position : Vector2 = Vector2(items_horizontal_offset, get_item_vertical() / 2.0 + vertical_separation)
	var item_index : int = 0
	for item in items:
		if p_index == item_index:
			return item_position
		item_position += Vector2(0.0, item.get_size().y + vertical_separation) 
		item_index += 1
	return item_position

func is_grabbing() -> bool:
	return grabbed_item_index != -1

func _on_item_selected(p_index : int) -> void:
	if is_instance_valid(selected_item) and p_index == selected_item.index:
		return
	select(p_index)
	emit_signal("item_selected", p_index)

func _on_item_mouse_entered(p_index : int) -> void:
	if is_grabbing():
		return
	emit_signal("item_mouse_entered", p_index)

func _on_item_mouse_exited(p_index : int) -> void:
	if is_grabbing():
		return
	emit_signal("item_mouse_exited", p_index)

func _on_item_grabbed(p_index : int) -> void:
	if is_grabbing():
		return
	grabbed_item_index = p_index
	update_items_z(p_index)

func update_items_z(p_index : int, p_except : int = -1) -> void:
	for item in items:
		if p_index > -1:
			item.set_z(AnimatedItem.Z.GRABBED if item.index == p_index else AnimatedItem.Z.UNDER) 
		elif item.index != p_except:
			item.set_z(AnimatedItem.Z.NORMAL)
			
func _on_item_dropped(_p_index : int) -> void:
	tween_reposition_grabbed()
	if grabbed_item_index == items[grabbed_item_index].temp_index:
		update_items_z(-1, grabbed_item_index)
		grabbed_item_index = -1
		return
	
	emit_signal("item_moved", grabbed_item_index, items[grabbed_item_index].temp_index)
	update_items_z(-1, grabbed_item_index)
	for item in items:
		item.index = item.temp_index
	items.sort_custom(reorder_by_temp_index)
	grabbed_item_index = -1

func _process(_delta) -> void:
	var mouse_position : Vector2 = get_local_mouse_position()
	var relative_mouse : Vector2 = mouse_position - last_mouse_position
	last_mouse_position = mouse_position
	
	if not is_grabbing():
		return
	
	if grabbed_item_index > items.size() -1:
		print("Grabbed item index out of range (%s)" % grabbed_item_index)
		return
	
	var grabbed_item : AnimatedItem = items[grabbed_item_index]

	grabbed_item.position.y += relative_mouse.y

	for item in items:
		if item == grabbed_item:
			continue
		if abs(grabbed_item.position.y - item.position.y) < item.get_size().y / 4.0:
			tween_move_item(item)


func tween_move_item(item : AnimatedItem) -> void:
	swap_temp_index(items[grabbed_item_index], item)
	if not is_instance_valid(item):
		return
	
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "position:y", get_item_position(item.temp_index).y, 0.25)

	await tween.finished

func swap_temp_index(item1 : AnimatedItem, item2 : AnimatedItem) -> void:
	var tmp = item1.temp_index
	item1.temp_index = item2.temp_index
	item2.temp_index = tmp

func tween_reposition_grabbed() -> void:
	var grabbed_item = items[grabbed_item_index]
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(grabbed_item, "position", get_item_position(grabbed_item.temp_index), 0.2)


func select(p_index : int) -> void:
	print("select called")
	if p_index < 0 or p_index >= items.size():
		return
	selected_item = items[p_index]
	for i in items.size():
		items[i].select(i == p_index)

func reorder_by_temp_index(a : AnimatedItem, b : AnimatedItem) -> bool:
	return a.temp_index < b.temp_index

func get_selected_index() -> int:
	if not is_instance_valid(selected_item):
		return -1
	return selected_item.index

func connect_all(p_item : AnimatedItem) -> void:
	for signal_name in signals:
		print("connecting ", signal_name)
		p_item.connect(signal_name, Callable(self, "_on_item_" + signal_name))

func _on_item_delete_requested(p_index : int) -> void:
	emit_signal("item_delete_requested" , p_index)
	
func _on_item_duplicate_requested(p_index : int) -> void:
	print("liste emet item_duplicate_requested")
	emit_signal("item_duplicate_requested" , p_index)

func delete_item(p_index : int) -> void:
	if selected_item == items[p_index]:
		selected_item = null
	items[p_index].freeze_texture()
	items[p_index].launch_delete_tween()
	items.remove_at(p_index)
	for i in items.size():
		items[i].set_indexes(i)
	reposition_after_delete()
	
func reposition_after_delete() -> void:
	var tween_number : int = 1
	
	for i : int in items.size():
		var item_pos : Vector2 = items[i].position
		var expected_pos : Vector2 = get_item_position(i)
		
		if item_pos != expected_pos:
			var tween : Tween= create_tween()
			tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
			tween.tween_interval(tween_number * 0.15)
			tween.tween_property(items[i], "position:y", expected_pos.y, 0.5)
			tween_number += 1
	if tween_number > 1:
		await get_tree().create_timer(tween_number * (0.15 + 0.5)).timeout
		autosize()

func reposition_after_insert(p_item):
	if items.size() < 2:
		p_item.position = get_item_position(p_item.index)
		return
		
	var tween : Tween = null
	for i : int in items.size():
		
		var item_pos : Vector2 = items[i].position
		var expected_pos : Vector2 = get_item_position(i)
		if p_item == items[i]:
			if not is_instance_valid(tween):
				tween = create_tween()
				tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
			tween.tween_property(p_item, "modulate:a", 1.0, 0.5).from(0.0)
			tween.parallel().tween_property(p_item, "scale", Vector2.ONE, 0.5).from(Vector2(0.1,0.1))
		if item_pos != expected_pos:
			tween.parallel().set_ease(Tween.EASE_OUT).tween_property(items[i], "position:y", expected_pos.y, 0.5)

	if is_instance_valid(tween):
		await tween.finished
	

func show_scroll_bar(p_active : bool) -> void:
	scrollbar.max_value = real_size_y
	scrollbar.page = size.y
	if scrollbar.visible != p_active:
		var tween : Tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).set_parallel(p_active)
		tween.tween_property(scrollbar, "modulate:a", 1.0 if p_active else 0.0, 0.5).from(0.0 if p_active else 1.0)
		tween.tween_callback(scrollbar.set_visible.bind(p_active))

func _on_v_scroll_bar_value_changed(p_value : float) -> void:
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(item_container, "position:y", -p_value, 0.2)
