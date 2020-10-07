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
export var remove_unused:= true
export var modified_files_only:= true
export var auto_on_save:= false
export var print_debug_output:= false
