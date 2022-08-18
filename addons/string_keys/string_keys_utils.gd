extends Node

const OPTIONS_DIRECTORY = "res://addons/string_keys/.options"
const OPTIONS_FILE_PATH = OPTIONS_DIRECTORY + "/string_keys_options.tres"

var _tag_seperator: String
var _key_is_before_tag: bool

func _init():
	var options = _get_options()
	_tag_seperator = options.tag_seperator
	_key_is_before_tag = options.key_is_before_tag


# return the key associated to the string
func sk(string: String) -> String :
	return _key_from_string(string)


# return the translated string associated with the key within the string
func sktr(string: String) -> String :
	return tr(_key_from_string(string))


func _get_options() -> StringKeysOptions:
	if not File.new().file_exists(OPTIONS_FILE_PATH): 
		var dir:= Directory.new()
		if not dir.dir_exists(OPTIONS_DIRECTORY):
			dir.make_dir(OPTIONS_DIRECTORY)
		ResourceSaver.save(OPTIONS_FILE_PATH, StringKeysOptions.new())
	var options = load(OPTIONS_FILE_PATH)
	return options


func _key_from_string(key: String) -> String:
	var tag_index:= key.find(_tag_seperator)
	if tag_index == -1:
		return key
	else:
		if _key_is_before_tag :
			return key.left(tag_index)
		else :
			return key
