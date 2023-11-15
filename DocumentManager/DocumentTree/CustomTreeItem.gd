extends Resource
class_name CustomTreeItem

enum TYPE { FOLDER, DOCUMENT }

var root_path : String = ""
var item_path : String = ""
var document_full_path : String = ""
var file_name : String = ""
var document_uid : int = -1
var child_items : Array[CustomTreeItem] = []
var date_created : Dictionary = {}
var last_modified : Dictionary = {}
var type : TYPE = TYPE.FOLDER
var editable : bool = true
var selectable : bool = true

var tree_item : TreeItem = null

func is_folder() -> bool:
	return type == TYPE.FOLDER
	
func is_document() -> bool:
	return type == TYPE.DOCUMENT
