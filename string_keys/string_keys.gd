tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/string_keys/string_keys_dock.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)
	#connect("resource_saved", dock, "add_to_modified_files")
	
	connect("resource_saved", self, "_something_was_saved")
	get_editor_interface().get_resource_filesystem().connect("resources_reload", self, "_resources_test")

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

func _resources_test(resources: PoolStringArray):
	print(resources)

func _something_was_saved(resource : Resource):
	print("Something was saved")
	print(resource.resource_path)
	#get_editor_interface().get_resource_filesystem().scan()

