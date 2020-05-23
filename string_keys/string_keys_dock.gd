tool
extends Node

#TODO:
#make it create the file if it doesn't exist
#Fixing backslashes in keys
#Trigger .csv reimport
#Store empty strings on locales without translations to make sure the keys work
#Throw error when set Locales don't match saved
#Make it so that errors cause it to stop the process
#Allow more flexibility with setting format (ex: allowing file formats to start with a . or not)
#Save and load settings/ presets
#Figure out what to do with progress bar
#Hide and make sure certian options are disabled when other are enabled
#Check all Tooltips are accurate and make sure to list what is allowed (IE: No \ in prefix/suffix)
#Check that all comments should be there
#Maybes:
#	Optimize options
#	Only allow open tscns that aren't in ignored paths
#	Paths to only include rather than ignore as well
#	Figure out how it can check binary files such as .vs visual scripts or binary .scn and .res
#	Option to automatically run on file save if performance is good, or add to list of modified files to check

#POTENTIAL ISSUES:
#Back slash \ and other special issues might be able to confuse what parts of a file are strings
#Certian situations may cause a problem when using an old .csv file as an input

#Test comment strings (Must remove addons from ignores path for this to work)
#	"$$This is a test key \"Quote\""
#   "Category$$Test key number 2 \\back\\ slashes \\"

var _working := false
var _files_to_search = []
var _modified_files = [] #######################################################################
var _allowed_formats = []
var _ignored_paths = []
var _keys = []
var _locales = []
var _csv_file = File.new()
var _old_keys = [] #keys that were already in .csv file, includes translations in pool array (2D)
var _removed_keys = []


func _on_Button_pressed():
	if _working: #Cancel work
		_done_working()
	else: #Start working
		#Display:
		_working = true
		$VBox/ProgressBar.show()
		$VBox/Button.text = "Cancel..."
		#Work
		_find_files_to_search()
		_search_files_for_keys()
		_get_or_make_csv_file($VBox/Grid/LineEdit_TranslationFile.text)
		_write_keys_to_csv_file()
		_done_working()

func _done_working():
	_working = false
	$VBox/ProgressBar.hide()
	$VBox/ProgressBar.value = 0
	$VBox/Button.text = "Create Translation File"
	_files_to_search = []
	_allowed_formats = []
	_ignored_paths = []
	_keys = []
	_locales = []
	_csv_file.close()
	_old_keys = []
	_removed_keys = []

#Finding files:
func _find_files_to_search():
	if $VBox/Grid/CheckBox_OpenTscnsOnly.pressed:
		_files_to_search = EditorScript.new().get_editor_interface().get_open_scenes()
		_print_if_allowed("\nStringKeys files to search: " + str(_files_to_search))
	else:
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
		_print_if_allowed("\nStringKeys files to search: " + str(_files_to_search))

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

func _write_keys_to_csv_file():
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
		_csv_file.open(_csv_file.get_path(), File.WRITE)
		_csv_file.store_csv_line(["key"] + _locales) #First line with locales
		var old_index := 0
		var new_index := 0
		while old_index < _old_keys.size() and new_index < _keys.size(): #Both left, compare new and old and add in alphabetical order
			var comparision = _old_keys[old_index][0].casecmp_to(_keys[new_index])
			print ("comparison: " + str(comparision)) ###################################################################
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
			print ("old")##########################################################################3
		while new_index < _keys.size(): #If only new keys left, add new
			_csv_file.store_csv_line([_keys[new_index], _text_from_key(_keys[new_index])] + _make_filler_strings(2))
			new_index += 1
			print("new")#############################################################################
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
	for i in range(0, _locales.size() - filled + 1): #Maybe 0 should be one?????????????????????????????????????????????
		array.append($VBox/Grid/LineEdit_FillerStrings.text)
	return array

#Options, warnings, disabling options:
func _on_CheckBox_ClearFile_toggled(button_pressed):
	$VBox/ClearFileWarning.visible = button_pressed

func _on_CheckBox_RemoveUnused_toggled(button_pressed):
	$VBox/RemoveUnusedWarning.visible = button_pressed

#Maybe warn to do full checks sometimes when using auto on save/modified only............................

#Other:
func _print_if_allowed(thing): ##########################################################TODO Option
	if $VBox/Grid/CheckBox_PrintOutput.pressed:
		print(thing)

func _append_array_to_array_unique(original: Array, addition: Array):
	for a in addition:
		if not original.has(a):
			original.append(a)
