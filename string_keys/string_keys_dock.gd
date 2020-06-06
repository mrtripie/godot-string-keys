tool
extends Node

#TODO:  (Add this to README)
#move auto on save to personal save file in User://
#Auto on save warning, modified only, clear, and remove
#make it create the file if it doesn't exist
#Skip writing to csv file if there's no keys. unless remove unused/clear (still make it to the end to save file hashes)
#Trigger .csv reimport  (maybe calling EditorFileSystem scan() dwould do the trick)
#a close() to every file.open()
#Make it so that errors cause it to stop the process (return true/false based on success and use an if where called)
#Allow more flexibility with setting format (ex: allowing file formats to start with a . or not)
#Hide and make sure certian options are disabled when other are enabled (modified only and clear file/remove unused!)
#Check all Tooltips are accurate and make sure to list what is allowed (IE: No \ in prefix/suffix)
#Check that all comments should be there
#Maybes:
#	Option button to clear file hashes for modified files may be good for long running projects
#	Presets so you can have multiple files scanning different key types (wont work with modified files w/o a redesign though)
#	See if you can find a way to deal with a way to deal with modified when different settings come in to play
#	Optimize options
#	Only allow open tscns that aren't in ignored paths  
#	Paths to only include rather than ignore as well
#	Figure out how it can check binary files such as .vs visual scripts or binary .scn and .res
#	Option to automatically run on file save if performance is good, or add to list of modified files to check

#LIKELY POTENTIAL ISSUES: (add to readme)
#Back slash \ and other special issues might be able to confuse what parts of a file are strings
#Certian situations may cause a problem when using an old .csv file as an input
#Probably shouldn't merge 2 members versions in version control

#KNOWN ISSUES:
#2 backslashes \\ in a row in a translation will be read by godot as 1, even though the generated file appears to be correct

#Formatting in code: (maybe add to readme)
#	"$$This is a simple test"
#	"$$This is a test key \"Quote\""
#   "Category$$Test key number 2 \\back\\ slashes \\"

var plugin : EditorPlugin
var _files_to_search = []
var _allowed_formats = []
var _ignored_paths = []
var _file_hashes : Dictionary #used to check if a file is modified
var _keys = []
var _locales = []
var _csv_file = File.new()
var _old_keys = [] #keys that were already in .csv file, includes translations in pool array (2D)
var _removed_keys = []
var _save_data := { #Make sure this is correct, ie: Open Tscns Only is not included#############################
	"translation_file" : "",
	"file_types_to_check" : "tscn, tres, gd, cs,",
	"paths_to_ignore" : ".git, .import, addons,",
	"locales" : "en,",
	"prefix" : "$$",
	"modified_only" : false,
	"auto_on_save" : false,
	"filler_strings" : "_",
	"text_from_key" : true,
	"clear_file" : false,
	"remove_unused" : false,
	"print_to_output" : false,
}

func _enter_tree():
	_load_options("options.sko") #.sko for current options, .skp for preset options
	plugin.connect("resource_saved", self, "auto_on_save")

func _exit_tree():
	_save_options("options.sko")

func _on_Button_pressed():
	_work()

func _work():
	_save_options("options.sko")
	_find_files_to_search()
	_track_modified_files()
	_search_files_for_keys()
	_get_or_make_csv_file($VBox/Grid/LineEdit_TranslationFile.text)
	_write_keys_to_csv_file($VBox/Grid/LineEdit_TranslationFile.text)
	_save_file_hashes()
	_done_working()

func _done_working():
	_files_to_search = []
	_allowed_formats = []
	_ignored_paths = []
	_file_hashes.clear()
	_keys = []
	_locales = []
	_csv_file.close()
	_old_keys = []
	_removed_keys = []

#Finding files:
func _find_files_to_search(): 
	#allowed formats:
	var _formats_unformatted = $VBox/Grid/TextEdit_FileTypes.text.split(",", false)
	for f in _formats_unformatted:
		_allowed_formats.append("." + f.strip_edges()) #add . and strip of spaces/new lines
	#ignored paths:
	var _ign_paths_unformatted = $VBox/Grid/TextEdit_PathsToIgnore.text.split(",", false)
	for p in _ign_paths_unformatted:
		_ignored_paths.append("res://" + p.strip_edges()) #add res and strip spaces/new lines
	#search:
	_files_to_search = _get_files_in_directory_recursive("res://")
	#print:
	_print_if_allowed("\nStringKeys allowed formats: " + str(_allowed_formats))
	_print_if_allowed("StringKeys ignored paths: " + str(_ignored_paths))

func _get_files_in_directory_recursive(path : String) -> Array:
	var dir = Directory.new()
	if dir.open(path) == OK:
		var file_paths = []
		dir.list_dir_begin(true, true) #Skip navigational and hidden, maybe shouldn't do hidden?
		var current_file = dir.get_next()
		while current_file != "":
			if dir.current_is_dir(): #look into a sub directory
				var full_dir_path = path + current_file
				if _is_path_allowed(full_dir_path):
					file_paths += _get_files_in_directory_recursive(full_dir_path + "/")
			else: #add a file
				if _is_file_allowed_format(current_file):
					file_paths.append(path + current_file)
			current_file = dir.get_next()
		return file_paths
	else:
		_print_if_allowed("ERROR: Couldn't open path: " + path + "  failed")
		return []

func _is_file_allowed_format(file_name : String) -> bool:
	for i in _allowed_formats:
		if file_name.ends_with(i):
			return true
	return false

func _is_path_allowed(path : String) -> bool:
	return not _ignored_paths.has(path)

#Finding string keys in files:
func _search_files_for_keys():
	for f in _files_to_search:
		_append_array_to_array_unique(_keys, _find_keys_in_file(f))
	_keys.sort() #make alphabetical
	_print_if_allowed("\nStringKeys keys found: " + str(_keys))

func _find_keys_in_file(file_path : String) -> Array:
	var file = File.new()
	file.open(file_path, File.READ)
	var file_text : String = file.get_as_text()
	var found_keys = []
	var is_in_string := false
	var found_string : String
	var can_leave_string := true #used so that \ doesn't cause issues with whether a " is the end of a string, or part of it
	for c in file_text:
		if c != "n" and not can_leave_string and is_in_string: #Removes any \ that should not be in the key
			found_string = found_string.trim_suffix("\\")
		if c == "\"" and can_leave_string: #character is an ", entering/leaving a string
			if is_in_string:
				if _is_string_a_key(found_string):
					found_keys.append(found_string)
				found_string = ""
				can_leave_string = true #now that it's exiting a string, allow it to leave next time
			is_in_string = not is_in_string 
		else: #is regular character, or couldn't leave due to a \
			if is_in_string: #then add this character
				found_string += c
				if c == "\\":
					can_leave_string = not can_leave_string #toggles in case of doubles
				else:
					can_leave_string = true #can always leave if last wasn't a \
	return found_keys

func _is_string_a_key(string : String) -> bool: #TODO: maybe a suffix
	return string.find($VBox/Grid/LineEdit_Prefix.text) != -1

#Saving to .csv file
func _get_or_make_csv_file(path: String):
	if path.get_file() != "": #Tries to make sure path is valid  TODO: needs improvement
		if _csv_file.file_exists(path) and not $VBox/Grid/CheckBox_ClearFile.pressed:
			_csv_file.open(path, File.READ)
			_locales = _csv_file.get_csv_line() as Array #first line for locales
			_locales.pop_front() #gets rid of the "key" in the first column
			var _file_length = _csv_file.get_len()
			while true:
				if _csv_file.get_position() == _file_length:
					break
				_old_keys.append(_csv_file.get_csv_line() as Array)
	else:
		print("Error: String Keys \"Translation File\" is invalid file name")

func _write_keys_to_csv_file(path: String):
	#Locales:
	var locales_unformatted = $VBox/Grid/TextEdit_Locales.text.split(",", false)
	var locales_index := 0
	var locales_are_valid := true
	for l in locales_unformatted:
		l = l.strip_edges()
		if _locales.size() > locales_index:
			if _locales[locales_index] != l:
				locales_are_valid = false #old and new locales mismatch, error
		else:
			_locales.append(l) #new locale added
		locales_index += 1
	_print_if_allowed("\nStringKeys locales: " + str(_locales))
	#Generating .csv:
	if locales_are_valid:
		_csv_file.open(path, File.WRITE)
		_csv_file.store_csv_line(["key"] + _locales) #First line with locales
		var old_index := 0
		var new_index := 0
		while old_index < _old_keys.size() and new_index < _keys.size(): #Both left, compare new and old and add in alphabetical order
			var comparision = _old_keys[old_index][0].casecmp_to(_keys[new_index])
			#print ("comparison: " + str(comparision)) ###################################################################
			if comparision == -1: #add next old key
				if (not _keys.has(_old_keys[old_index])) and $VBox/Grid/CheckBox_RemoveUnused.pressed:
					_removed_keys.append(_old_keys[old_index][0])
				else:
					_csv_file.store_csv_line(_old_keys[old_index] + _make_filler_strings(_old_keys[old_index].size()))
				old_index += 1
			elif comparision == 1: #add next new key
				_csv_file.store_csv_line([_keys[new_index], _text_from_key(_keys[new_index])] + _make_filler_strings(2))
				new_index += 1
			elif comparision == 0: #keys are equal, skip new and use old to keep manual work
				_csv_file.store_csv_line(_old_keys[old_index] + _make_filler_strings(_old_keys[old_index].size()))
				old_index += 1
				new_index += 1
			else:
				print ("Error: StringKeys old key comparison failed")
		while old_index < _old_keys.size(): #If only old keys left, add old
			if (not _keys.has(_old_keys[old_index])) and $VBox/Grid/CheckBox_RemoveUnused.pressed:
				_removed_keys.append(_old_keys[old_index][0])
			else:
				_csv_file.store_csv_line(_old_keys[old_index] + _make_filler_strings(_old_keys[old_index].size()))
			old_index += 1
			#print ("old")##########################################################################3
		while new_index < _keys.size(): #If only new keys left, add new
			_csv_file.store_csv_line([_keys[new_index], _text_from_key(_keys[new_index])] + _make_filler_strings(2))
			new_index += 1
			#print("new")#############################################################################
		_print_if_allowed("StringKeys: Keys saved to .csv file")
		if $VBox/Grid/CheckBox_RemoveUnused.pressed:
			_print_if_allowed("StringKeys Removed Keys: " + str(_removed_keys))
	else:
		print("Error: StringKeys locales don't match .csv file, failed")

func _text_from_key(key : String) -> String:
	if $VBox/Grid/CheckBox_TextFromKey.pressed:
		return key.split($VBox/Grid/LineEdit_Prefix.text, true, 1)[1] #get first part after prefix
	else:
		return $VBox/Grid/LineEdit_FillerStrings.text

func _make_filler_strings(filled : int) -> Array: #fills in empty slots, as godot doesn't use keys that don't have a translation in all locales
	var array = []
	for i in range(0, _locales.size() - filled + 1):
		array.append($VBox/Grid/LineEdit_FillerStrings.text)
	return array

#Modified files:
func _track_modified_files(): #tracks and compares sha256 of files, if modified only, removes unmodified from _files_to_search
	var file := File.new()
	if file.file_exists("user://string_keys_file_hashes.skfh"):
		file.open("user://string_keys_file_hashes.skfh", File.READ)
		_file_hashes = file.get_var()
	var modified_files = []
	for f in _files_to_search:
		var old_sha256 = _file_hashes.get(f) #null if new file, will be modified
		var new_sha256 = file.get_sha256(f)
		if old_sha256 != new_sha256:
			modified_files.append(f)
			_file_hashes[f] = new_sha256
	if $VBox/Grid/CheckBox_ModifiedOnly.pressed:
		_files_to_search = modified_files
		_print_if_allowed("\nStringKeys (modified) files to search: " + str(_files_to_search))
	else:
		_print_if_allowed("\nStringKeys files to search: " + str(_files_to_search))

func _save_file_hashes(): #only do after everything runs error free
	var file := File.new()
	file.open("user://string_keys_file_hashes.skfh", File.WRITE)
	file.store_var(_file_hashes)
	file.close()

#Auto run on save:
func auto_on_save(_resource : Resource):
	#resource_saved signal is BEFORE the save, waiting until the filesytem has channged
	#makes it run after the save. Just using the filesystem_changed signal alone wouldn't
	#work because when it changes the translation file, making it run again
	yield(plugin.get_editor_interface().get_resource_filesystem(), "filesystem_changed") 
	if $VBox/Grid/CheckBox_AutoRunOnSave.pressed:
		print("Running StringKeys on save")
		_work()

#Saving/loading options:
func _save_options(file_name : String):
	#set options from buttons:
	_save_data.translation_file = $VBox/Grid/LineEdit_TranslationFile.text
	_save_data.file_types_to_check = $VBox/Grid/TextEdit_FileTypes.text
	_save_data.paths_to_ignore = $VBox/Grid/TextEdit_PathsToIgnore.text
	_save_data.locales = $VBox/Grid/TextEdit_Locales.text
	_save_data.prefix = $VBox/Grid/LineEdit_Prefix.text
	_save_data.modified_only = $VBox/Grid/CheckBox_ModifiedOnly.pressed
	_save_data.auto_on_save = $VBox/Grid/CheckBox_AutoRunOnSave.pressed
	_save_data.filler_strings = $VBox/Grid/LineEdit_FillerStrings.text
	_save_data.text_from_key = $VBox/Grid/CheckBox_TextFromKey.pressed
	_save_data.clear_file = $VBox/Grid/CheckBox_ClearFile.pressed
	_save_data.remove_unused = $VBox/Grid/CheckBox_RemoveUnused.pressed
	_save_data.print_to_output = $VBox/Grid/CheckBox_PrintOutput.pressed
	#save options:
	var dir := Directory.new()
	dir.make_dir_recursive("res://addons/string_keys/options/")
	var file := File.new()
	file.open("res://addons/string_keys/options/" + file_name, File.WRITE)
	file.store_string(to_json(_save_data))
	file.close()

func _load_options(file_name : String):
	#load options:
	var file := File.new()
	if file.file_exists("res://addons/string_keys/options/" + file_name):
		file.open("res://addons/string_keys/options/" + file_name, File.READ)
		_save_data = parse_json(file.get_as_text())
		file.close()
	#set option buttons:
	$VBox/Grid/LineEdit_TranslationFile.text = _save_data.translation_file
	$VBox/Grid/TextEdit_FileTypes.text = _save_data.file_types_to_check
	$VBox/Grid/TextEdit_PathsToIgnore.text = _save_data.paths_to_ignore
	$VBox/Grid/TextEdit_Locales.text = _save_data.locales
	$VBox/Grid/LineEdit_Prefix.text = _save_data.prefix
	$VBox/Grid/CheckBox_ModifiedOnly.pressed = _save_data.modified_only
	$VBox/Grid/CheckBox_AutoRunOnSave.pressed = _save_data.auto_on_save
	$VBox/Grid/LineEdit_FillerStrings.text = _save_data.filler_strings
	$VBox/Grid/CheckBox_TextFromKey.pressed = _save_data.text_from_key
	$VBox/Grid/CheckBox_ClearFile.pressed = _save_data.clear_file
	$VBox/Grid/CheckBox_RemoveUnused.pressed = _save_data.remove_unused
	$VBox/Grid/CheckBox_PrintOutput.pressed = _save_data.print_to_output

#Options, warnings, disabling options:
func _on_CheckBox_ClearFile_toggled(button_pressed):
	$VBox/ClearFileWarning.visible = button_pressed

func _on_CheckBox_RemoveUnused_toggled(button_pressed):
	$VBox/RemoveUnusedWarning.visible = button_pressed

func _on_CheckBox_ModifiedOnly_toggled(button_pressed):
	pass

#Maybe warn to do full checks sometimes when using auto on save/modified only............................

#Other:
func _print_if_allowed(thing): ##########################################################TODO Option
	if $VBox/Grid/CheckBox_PrintOutput.pressed:
		print(thing)

func _append_array_to_array_unique(original: Array, addition: Array):
	for a in addition:
		if not original.has(a):
			original.append(a)


