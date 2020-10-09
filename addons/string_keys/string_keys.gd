class_name StringKeys
extends Reference

var options: StringKeysOptions

var _files_to_search:= []
var _file_hashes:= {} #used to check if a file is modified
var _patterns:= []
var _keys:= []
var _old_keys:= [] #keys that were already in .csv file, includes translations in pool array (2D)
var _removed_keys:= []

func generate_translation_file(sk_options: StringKeysOptions):
	options = sk_options
	_files_to_search = _get_files_in_directory_recursive("res://")
#	_track_modified_files()
	parse_pattern_strings()
	_search_files_for_keys()
#	if _keys.size() > 0 or options.remove_unused:
#		if _get_or_make_csv_file(LineEdit_TranslationFile.text): #true = no errors, continue
#			if _write_keys_to_csv_file(LineEdit_TranslationFile.text):
#				_save_file_hashes() #Only run this if there were no errors, otherwise file will be incorrect
#				plugin.get_editor_interface().get_resource_filesystem().scan() #Triggers reimport of csv file
#				print("StringKeys succesful")
#	else:
#		_save_file_hashes() #Ran without error, but none of the modified files had changes to add
#		print("StringKeys no changes to add")


func _get_files_in_directory_recursive(search_path : String) -> Array:
	var dir:= Directory.new()
	if dir.open(search_path) != OK:
		_print_if_allowed("ERROR: Couldn't open search_path: " + search_path + "  failed")
		return []
	var file_paths = []
	dir.list_dir_begin(true, false) #Skip navigational, don't skip hidden
	var current_file = dir.get_next()
	while current_file != "":
		if dir.current_is_dir():
			var dir_path = search_path + current_file + "/"
			if not options.directories_to_ignore.has(dir_path):
				file_paths += _get_files_in_directory_recursive(dir_path)
		else:
			if _is_allowed_file_type(current_file):
				file_paths.append(search_path + current_file)
		current_file = dir.get_next()
	return file_paths


func _is_allowed_file_type(file_name : String) -> bool:
	for ft in options.file_types_to_search:
		if file_name.ends_with(ft):
			return true
	return false


func _search_files_for_keys():
	for f in _files_to_search:
		if f.ends_with(".scn"): #binary scene
			_append_array_to_array_unique(_keys, _find_keys_in_binary_scn_or_res(f, "user://sk_temp.tscn"))
		elif f.ends_with(".res"): #binary resource
			_append_array_to_array_unique(_keys, _find_keys_in_binary_scn_or_res(f, "user://sk_temp.tres"))
		elif f.ends_with(".vs"): #visual script (currently always binary)
			_append_array_to_array_unique(_keys, _find_keys_in_binary_visual_script(f))
		else: #consider (hope) its a text file
			_append_array_to_array_unique(_keys, _find_keys_in_text_file(f))
	_keys.sort() #make alphabetical
	_print_if_allowed("\nStringKeys keys found: " + str(_keys))


func _find_keys_in_binary_scn_or_res(file_path : String, temp_path : String) -> Array:
	ResourceSaver.save(temp_path, load(file_path)) #converts binary version to text version and saves as temp file
	var keys:= _find_keys_in_text_file(temp_path)
	Directory.new().remove(temp_path)
	return keys


func _find_keys_in_binary_visual_script(file_path : String) -> Array:
	var scene := PackedScene.new() #create a scene and node to pack the script to
	var node := Node.new()
	node.set_script(load(file_path))
	node.get_script().resource_local_to_scene = true #pack the script in the scene
	node.get_script().resource_path = ""
	scene.pack(node)
	ResourceSaver.save("user://sk_temp.tscn", scene) #save to temporary .tscn, find keys, and remove file
	var keys:= _find_keys_in_text_file("user://sk_temp.tscn")
	Directory.new().remove("user://sk_temp.tscn")
	return keys


func _find_keys_in_text_file(file_path : String) -> Array:
	var file = File.new()
	file.open(file_path, File.READ)
	var file_text: String = file.get_as_text()
	file.close()
	var found_keys:= []
	var pattern_indices:= {}
	var search_index:= 0
	var keep_going:= true
	while(keep_going):
		# update the indices of the first place each prefix was found
		for p in _patterns:
			var i = pattern_indices.get(p, -1)
			if i < search_index:
				var next_prefix_index:= file_text.find(p.prefix, search_index)
				pattern_indices[p] = next_prefix_index
				if next_prefix_index == -1:
					pattern_indices.erase(p)
		
		if pattern_indices.empty():
			break
		
		# find the suffix for the pattern with the earliest index (add length of prefix to shorten search)
		var pattern: Pattern
		var prefix_index: int = 999999999999
		for p in pattern_indices.keys():
			if pattern_indices.get(p) < prefix_index:
				print("earlist")
				prefix_index = pattern_indices.get(p)
				pattern = p
		
		var suffix_index = file_text.find(pattern.suffix, prefix_index + pattern.prefix.length())
		if suffix_index == -1:
			pattern_indices.erase(pattern)
			search_index = prefix_index
		else:
			search_index = suffix_index + pattern.suffix.length()
			var prefix_end = prefix_index + pattern.prefix.length()
			found_keys.append(file_text.substr(prefix_end, suffix_index - prefix_end))
		
		keep_going = not pattern_indices.empty()
	return found_keys


func _append_array_to_array_unique(original: Array, addition: Array):
	for a in addition:
		if not original.has(a):
			original.append(a)


func _print_if_allowed(string: String):
	if options.print_debug_output:
		print(string)


func parse_pattern_strings():
	for p in options.patterns_to_search:
		parse_pattern_string(p)


func parse_pattern_string(string: String):
	var prefix_end:= string.find("STR_KEY")
	if prefix_end == -1:
		print("StringKeys Error: " + string + " is invalid pattern")
		return
	var pattern = Pattern.new()
	pattern.prefix = string.left(prefix_end)
	pattern.suffix = string.right(prefix_end + 7)
	_patterns.append(pattern)


class Pattern extends Reference:
	var prefix: String
	var suffix: String
