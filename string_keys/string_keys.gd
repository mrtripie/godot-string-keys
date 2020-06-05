tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/string_keys/string_keys_dock.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)
	connect("resource_saved", dock, "auto_on_save")


func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

