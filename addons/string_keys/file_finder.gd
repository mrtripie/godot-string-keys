class_name SkFileFinder
extends Reference

var directory: String
var file_types: Array
var ignored_directories: Array

func _init(dir: String, f_types: Array, ignored_dirs: Array):
	directory = dir
	file_types = f_types
	ignored_directories = ignored_dirs


func find_files() -> Array:
	return _get_files_in_directory_recursive(directory)


func _get_files_in_directory_recursive(search_path : String) -> Array:
	var dir:= Directory.new()
	if dir.open(search_path) != OK:
		print("ERROR: Couldn't open search_path: " + search_path + "  failed")
		return []
	var file_paths = []
	dir.list_dir_begin(true, false) #Skip navigational, don't skip hidden
	var current_file = dir.get_next()
	while current_file != "":
		if dir.current_is_dir():
			var dir_path = search_path + current_file + "/"
			if not ignored_directories.has(dir_path):
				file_paths += _get_files_in_directory_recursive(dir_path)
		else:
			if _is_allowed_file_type(current_file):
				file_paths.append(search_path + current_file)
		current_file = dir.get_next()
	return file_paths


func _is_allowed_file_type(file_name : String) -> bool:
	for ft in file_types:
		if file_name.ends_with(ft):
			return true
	return false
