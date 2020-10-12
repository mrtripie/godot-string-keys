class_name StringKeys
extends Reference

var options: StringKeysOptions

var _files_to_search:= []
var _file_hashes:= {} #used to check if a file is modified
var _keys:= []
var _old_keys:= [] #keys that were already in .csv file, includes translations in pool array (2D)
var _removed_keys:= []

func generate_translation_file(sk_options: StringKeysOptions):
	options = sk_options
	
	if not _is_translation_file_path_valid(options.translation_file):
		print("\nStringKeys ERROR: translation file path invalid")
		return
	
	var file_finder:= SkFileFinder.new("res://", options.file_types_to_search, options.directories_to_ignore)
	_files_to_search = file_finder.find_files()

#	_track_modified_files()
	
	var key_finder:= SkKeyFinder.new()
	key_finder.compile_patterns(options.patterns_to_search)
	_keys = key_finder.get_keys_in_files(_files_to_search)
	_print_if_allowed("\nStringKeys keys found: " + str(_keys))
	
	if _keys.size() > 0 or options.remove_unused:
		var csv_writer:= SkCsvWriter.new(options.translation_file, options.tag_seperator)
		csv_writer.read_old_csv_file()
		csv_writer.write_keys_to_csv_file(_keys, options.locales, options.remove_unused)
		if csv_writer.write_successful:
#			_save_file_hashes() #Only run this if there were no errors, otherwise file will be incorrect
#			plugin.get_editor_interface().get_resource_filesystem().scan() #Triggers reimport of csv file
#			print("StringKeys succesful")
			pass
#	else:
#		_save_file_hashes() #Ran without error, but none of the modified files had changes to add
#		print("StringKeys no changes to add")


func _is_translation_file_path_valid(path: String) -> bool:
	return  path.get_file() != "" and path.ends_with(".csv")


func _print_if_allowed(string: String):
	if options.print_debug_output:
		print(string)
