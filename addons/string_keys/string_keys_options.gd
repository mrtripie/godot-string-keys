tool
class_name StringKeysOptions
extends Resource

export var translation_file:= "res://localization/translations.csv"
export(Array, String) var patterns_to_search:= ([
	"tr(\"STR_KEY\")",
	"Tr(\"STR_KEY\")",
	"text = \"STR_KEY\"",
	"title = \"STR_KEY\"",
	"hint_tooltip = \"STR_KEY\"",
	])
export(Array, String) var file_types_to_search:= ([
	".gd",
	".cs",
	".vs",
	".tscn",
	".tres",
	".scn",
	".res",
	]) setget set_file_types_to_search
export(Array, String) var directories_to_ignore:= ([
	"res://.git/",
	"res://.import/",
	"res://addons/",
	"res://localization/",
	])
export(Array, String) var locales:= ["en"]
export var tag_seperator:= "$$"
export var require_tag:= false
export var remove_unused:= true setget set_remove_unused
export var modified_files_only:= false setget set_modified_files_only
export var print_debug_output:= false

var editor_inspector: EditorInspector # allows interactively correcting invalid options

func set_file_types_to_search(value: Array):
	print ("ft")
	var file_types:= []
	for ft in value:
		if ft.begins_with("."):
			file_types.append(ft)
		else:
			file_types.append("." + ft)
			print("false")
	file_types_to_search = file_types
	if editor_inspector:
		editor_inspector.refresh()


# remove_unused and modified_files_only are incompatible, so they need to turn off the other:
func set_remove_unused(value: bool):
	remove_unused = value
	if value:
		modified_files_only = false
		if editor_inspector:
			editor_inspector.refresh()


func set_modified_files_only(value: bool):
	modified_files_only = value
	if value:
		remove_unused = false
		if editor_inspector:
			editor_inspector.refresh()

