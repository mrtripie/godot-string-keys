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
	])
export(Array, String) var paths_to_ignore:= ([
	".import",
	"addons",
	".git",
	])
export(Array, String) var locales:= ["en"]
export var context_info_seperator:= "::"
export var text_from_key:= true
export var remove_unused:= true setget set_remove_unused
export var modified_files_only:= false setget set_modified_files_only
export var print_debug_output:= false

var editor_inspector: EditorInspector

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

