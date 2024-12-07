extends Node
class_name UndoRedoManager

signal undo_redo_modified

var actions : Array[UndoRedoAction] = []
var undone_actions : Array[UndoRedoAction] = []

func can_undo() -> bool:
	return not actions.is_empty()
	
func can_redo() -> bool:
	return not undone_actions.is_empty()


func add_action(p_name : String, p_args : Array = []):
	print("adding action %s"%p_name)
	var new_action : UndoRedoAction = UndoRedoAction.new()
	new_action.action_name = p_name
	new_action.dispatch_args(p_args)
	actions.append(new_action)
	if not undone_actions.is_empty():
		delete_undone_actions()
	emit_signal("undo_redo_modified")
	print(actions)

func undo():
	print("undo")
	var undo_action : UndoRedoAction = actions.pop_back()
	undone_actions.append(undo_action)
	emit_signal("undo_redo_modified")
	undo_action.undo()
	
func redo():
	print("redo")
	var redo_action = undone_actions.pop_back()
	actions.append(redo_action)
	emit_signal("undo_redo_modified")
	redo_action.redo()

func delete_undone_actions():
	print("need to delete all undone actions")
	undone_actions.clear()
