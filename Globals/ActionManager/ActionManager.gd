extends Node
class_name ActionManager

signal undo_redo_modified

var undo_stack : Array[Action] = []
var redo_stack : Array[Action] = []

func can_undo() -> bool:
	return not undo_stack.is_empty()
	
func can_redo() -> bool:
	return not redo_stack.is_empty()

func do_action(p_action : Action) -> void:
	p_action.execute()
	undo_stack.append(p_action)
	redo_stack.clear()
	emit_signal("undo_redo_modified")

func undo() -> void:
	var undo_action : Action = undo_stack.pop_back()
	redo_stack.append(undo_action)
	undo_action.unexecute()
	emit_signal("undo_redo_modified")
	
func redo() -> void:
	var redo_action : Action = redo_stack.pop_back()
	undo_stack.append(redo_action)
	redo_action.execute()
	emit_signal("undo_redo_modified")
