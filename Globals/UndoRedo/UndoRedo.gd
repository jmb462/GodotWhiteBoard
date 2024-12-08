extends Node
class_name UndoRedoManager

signal undo_redo_modified

var undo_stack : Array[Action] = []
var redo_stack : Array[Action] = []

func can_undo() -> bool:
	return not undo_stack.is_empty()
	
func can_redo() -> bool:
	return not redo_stack.is_empty()

func add_action(p_action : Action) -> void:
	undo_stack.append(p_action)
	if not redo_stack.is_empty():
		delete_redo_stack()
	emit_signal("undo_redo_modified")

func undo() -> void:
	print("undo")
	var undo_action : Action = undo_stack.pop_back()
	redo_stack.append(undo_action)
	emit_signal("undo_redo_modified")
	undo_action.undo()
	
func redo() -> void:
	print("redo")
	var redo_action : Action = redo_stack.pop_back()
	undo_stack.append(redo_action)
	emit_signal("undo_redo_modified")
	redo_action.redo()

func delete_redo_stack() -> void:
	print("need to delete all undone actions")
	redo_stack.clear()
