class_name SkModifiedFileTracker
extends Reference

var modified_files: Array
var modification_state_file_path: String

var _file_hashes: Dictionary

func _init(mod_state_file_path: String):
	modification_state_file_path = mod_state_file_path


func check_for_modifications(files_to_check): #tracks and compares sha256 of files, adds modified to modified_files
	var file := File.new()
	if file.file_exists(modification_state_file_path):
		file.open(modification_state_file_path, File.READ)
		_file_hashes = file.get_var()
	modified_files = []
	for f in files_to_check:
		var old_hash = _file_hashes.get(f) #null if new file, will be appended to modified_files
		var new_hash = file.get_sha256(f)
		if old_hash != new_hash:
			modified_files.append(f)
			_file_hashes[f] = new_hash


func save_modification_state(): #only do after everything runs error free
	var file := File.new()
	file.open(modification_state_file_path, File.WRITE)
	for fn in _file_hashes.keys():
		if not file.file_exists(fn):
			_file_hashes.erase(fn)
	file.store_var(_file_hashes)
	file.close()
