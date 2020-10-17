class_name SkKeyFinder
extends Reference

var require_tag: bool
var tag_seperator: String

var _patterns: Array

func _init(req_tag: bool, tag_sep: String):
	require_tag = req_tag
	tag_seperator = tag_sep


class Pattern extends Reference:
	var prefix: String
	var suffix: String


func compile_patterns(pattern_strings: Array):
	_patterns.clear()
	for ps in pattern_strings:
		_compile_pattern_string(ps)


func _compile_pattern_string(string: String):
	var prefix_end:= string.find("STR_KEY")
	if prefix_end == -1:
		print("StringKeys Error: " + string + " is invalid pattern, doesn't include STR_KEY")
		return
	var pattern = Pattern.new()
	pattern.prefix = string.left(prefix_end)
	pattern.suffix = string.right(prefix_end + 7)
	if pattern.prefix == "":
		print("StringKeys Error: " + string + " is invalid pattern, doesn't include prefix")
		return
	if pattern.suffix == "":
		print("StringKeys Error: " + string + " is invalid pattern, doesn't include suffix")
		return
	_patterns.append(pattern)


func get_keys_in_files(files: Array) -> Array:
	var keys:= []
	for f in files:
		if f.ends_with(".scn"): #binary scene
			_append_array_to_array_unique(keys, _get_keys_in_binary_scn_or_res(f, "user://sk_temp.tscn"))
		elif f.ends_with(".res"): #binary resource
			_append_array_to_array_unique(keys, _get_keys_in_binary_scn_or_res(f, "user://sk_temp.tres"))
		elif f.ends_with(".vs"): #visual script (currently always binary)
			_append_array_to_array_unique(keys, _get_keys_in_binary_visual_script(f))
		else: #consider (hope) its a text file
			_append_array_to_array_unique(keys, _get_keys_in_text_file(f))
	keys.sort() #make alphabetical
	return keys


func _get_keys_in_binary_scn_or_res(file_path : String, temp_path : String) -> Array:
	ResourceSaver.save(temp_path, load(file_path)) #converts binary version to text version and saves as temp file
	var keys:= _get_keys_in_text_file(temp_path)
	Directory.new().remove(temp_path)
	return keys


func _get_keys_in_binary_visual_script(file_path : String) -> Array:
	var scene := PackedScene.new() #create a scene and node to pack the script to
	var node := Node.new()
	node.set_script(load(file_path))
	node.get_script().resource_local_to_scene = true #pack the script in the scene
	node.get_script().resource_path = ""
	scene.pack(node)
	ResourceSaver.save("user://sk_temp.tscn", scene) #save to temporary .tscn, find keys, and remove file
	var keys:= _get_keys_in_text_file("user://sk_temp.tscn")
	Directory.new().remove("user://sk_temp.tscn")
	return keys


func _get_keys_in_text_file(file_path: String) -> Array:
	var file = File.new()
	file.open(file_path, File.READ)
	var file_text: String = file.get_as_text()
	file.close()
	return _get_keys_in_text(file_text)


func _get_keys_in_text(text: String) -> Array:
	var found_keys:= []
	var pattern_indices:= {}
	var search_index:= 0
	var keep_searching:= true
	while(keep_searching):
		# update the indices of the first place each prefix was found
		for p in _patterns:
			var i = pattern_indices.get(p, -1)
			if i < search_index:
				var next_prefix_start:= text.find(p.prefix, search_index)
				pattern_indices[p] = next_prefix_start
				if next_prefix_start == -1:
					pattern_indices.erase(p)
		
		if pattern_indices.empty():
			break
		
		# find the earliest pattern prefix
		var pattern: Pattern
		var prefix_start:= 999999999999
		for p in pattern_indices.keys():
			if pattern_indices.get(p) < prefix_start:
				prefix_start = pattern_indices.get(p)
				pattern = p
		
		# append the key if the suffix is found
		var suffix_start = text.find(pattern.suffix, prefix_start + pattern.prefix.length())
		if suffix_start == -1:
			pattern_indices.erase(pattern)
			search_index = prefix_start
		else:
			search_index = suffix_start + pattern.suffix.length()
			var prefix_end = prefix_start + pattern.prefix.length()
			var key_length = suffix_start - prefix_end
			var key = text.substr(prefix_end, key_length)
			if require_tag:
				if key.find(tag_seperator) > -1:
					found_keys.append(key)
			else:
				found_keys.append(key)
		
		keep_searching = not pattern_indices.empty()
	return found_keys


func _append_array_to_array_unique(original: Array, addition: Array):
	for a in addition:
		if not original.has(a):
			original.append(a)
