extends PanelContainer

signal new_button_pressed
signal previous_button_pressed
signal next_button_pressed
signal clear_button_pressed
signal document_manager_requested
signal board_requested
signal delete_document_requested
signal new_document_requested
signal duplicate_document_requested
signal new_folder_requested
signal undo_requested
signal redo_requested

@onready var h_box : HBoxContainer = $HBox
@onready var new_button : Button = $HBox/New
@onready var previous_button : Button = $HBox/Previous
@onready var next_button : Button = $HBox/Next
@onready var clear_button : Button = $HBox/Clear
@onready var page_number : Label = $HBox/PageNumber
@onready var board_button : Button = $HBox/Board
@onready var documents_button : Button = $HBox/Documents
@onready var delete_document_button : Button = $HBox/Documents
@onready var undo_button = $HBox/Undo
@onready var redo_button = $HBox/Redo

func _ready() -> void:
	Undo.connect("undo_redo_modified", _on_undo_redo_modified)
	connect("undo_requested", Undo.undo)
	connect("redo_requested", Undo.redo)

func _on_new_pressed() -> void:
	emit_signal("new_button_pressed")


func _on_previous_pressed() -> void:
	emit_signal("previous_button_pressed")


func _on_next_pressed() -> void:
	emit_signal("next_button_pressed")


func _on_clear_pressed() -> void:
	emit_signal("clear_button_pressed")



func _on_main_board_boards_changed(p_current_board : int, p_total_boards : int) -> void:
	previous_button.disabled = p_current_board < 1
	next_button.disabled = p_current_board == p_total_boards - 1 or p_total_boards < 2
	page_number.text = "%s / %s" % [p_current_board + 1, p_total_boards]

func _on_widgets_count_modified(p_count : int) -> void:
	clear_button.disabled = p_count == 0

func _on_undo_redo_modified() -> void:
	undo_button.disabled = not Undo.can_undo()
	redo_button.disabled = not Undo.can_redo()
	
func _on_documents_pressed() -> void:
	print("_on_document_pressed")
	emit_signal("document_manager_requested")
	get_tree().call_group("board_page", "hide")
	get_tree().call_group("documents_page", "show")
	
func _on_board_pressed() -> void:
	emit_signal("board_requested")
	show_only_board_buttons()
	
func show_only_board_buttons() -> void:
	get_tree().call_group("board_page", "show")
	get_tree().call_group("documents_page", "hide")


func _on_delete_document_pressed() -> void:
	emit_signal("delete_document_requested")


func _on_new_document_pressed() -> void:
	emit_signal("new_document_requested")


func _on_duplicate_document_pressed() -> void:
	emit_signal("duplicate_document_requested")


func _on_new_folder_pressed() -> void:
	emit_signal("new_folder_requested")


func _on_undo_pressed():
	emit_signal("undo_requested")


func _on_redo_pressed():
	emit_signal("redo_requested")
