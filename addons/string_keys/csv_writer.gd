class_name SkCsvWriter
extends Reference

var path: String
var tag_seperator: String

var removed_keys:= [] # not necessary unless printing, could be removed for performance (though not many are likely to be removed)
var write_successful:= false

var _old_locales: Array
var _old_keys:= []

func _init(file_path: String, key_tag_seperator: String):
	path = file_path
	tag_seperator = key_tag_seperator


func read_old_csv_file():
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		_old_locales = file.get_csv_line() as Array
		_old_locales.remove(0) #gets rid of the "key" in the first column
		var _file_length = file.get_len()
		while true:
			if file.get_position() == _file_length:
				break
			_old_keys.append(file.get_csv_line() as Array)
		file.close()


func write_keys_to_csv_file(keys: Array, locales: Array, remove_unused: bool):
	if _are_locales_invalid(_old_locales, locales):
		print("Error: StringKeys locales don't match .csv file, failed")
		write_successful = false
		return
	
	_make_sure_directory_exists()
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_csv_line(["key"] + locales) #First line with locales
	var old_index := 0
	var new_index := 0
	while old_index < _old_keys.size() and new_index < keys.size(): #Both left, compare new and old and add in alphabetical order
		var comparision = _old_keys[old_index][0].casecmp_to(keys[new_index])
		if comparision == -1: #add next old key
			if (not keys.has(_old_keys[old_index])) and remove_unused:
				removed_keys.append(_old_keys[old_index][0])
			else:
				file.store_csv_line(_old_keys[old_index] + _make_filler_strings(_old_keys[old_index].size()))
			old_index += 1
		elif comparision == 1: #add next new key
			file.store_csv_line([keys[new_index], _text_from_key(keys[new_index])] + _make_filler_strings(2))
			new_index += 1
		elif comparision == 0: #keys are equal, skip new and use old to keep manual work
			file.store_csv_line(_old_keys[old_index] + _make_filler_strings(_old_keys[old_index].size()))
			old_index += 1
			new_index += 1
		else:
			print ("Error: StringKeys old key comparison failed")
	while old_index < _old_keys.size(): #If only old keys left, add old
		if (not keys.has(_old_keys[old_index])) and remove_unused:
			removed_keys.append(_old_keys[old_index][0])
		else:
			file.store_csv_line(_old_keys[old_index] + _make_filler_strings(_old_keys[old_index].size()))
		old_index += 1
	while new_index < keys.size(): #If only new keys left, add new
		file.store_csv_line([keys[new_index], _text_from_key(keys[new_index])] + _make_filler_strings(2))
		new_index += 1
	file.close()
	print("StringKeys: Keys saved to .csv file")
	write_successful = true


# locales are invalid if the new ones don't match the old (the new can have additional locales added though)
func _are_locales_invalid(l1: Array, l2: Array) -> bool:
	for i in range(0, min(l1.size(), l2.size()) - 1):
		if l1[i] != l2[i]:
			return true
	return false


func _make_sure_directory_exists():
	var dir:= Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())


func _text_from_key(key: String) -> String:
	var tag_index:= key.find(tag_seperator)
	if tag_index == -1:
		return key
	else:
		return key.right(tag_index + tag_seperator.length())


func _make_filler_strings(filled: int) -> Array: #fills in empty slots, as godot doesn't use keys that don't have a translation in all locales
	var array = []
	for i in range(0, _old_locales.size() - filled + 1):
		array.append("")
	return array
