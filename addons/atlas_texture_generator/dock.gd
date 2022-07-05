tool
extends Control

var resource_file_system: EditorFileSystem = null

var _file_paths := PoolStringArray()
var _output_path := "res://texture_atlas.png"

func _ready() -> void:
	$Input/FilePath.text = _output_path


func _on_SelectPath_pressed() -> void:
	$OutputFileDialog.popup_centered()

func _on_MakeAtlas_pressed() -> void:
	$FileDialog.popup_centered()


func _on_OutputFileDialog_confirmed() -> void:
	var dialog = $OutputFileDialog
	_output_path = dialog.current_dir + "/" + dialog.get_line_edit().text
	if _output_path.get_extension().empty() and not dialog.filters.empty():
		var filter = dialog.filters[0]
		var extension = filter.substr(1, filter.find(" "))
		_output_path += extension
	
	$Input/FilePath.text = _output_path

func _on_FileDialog_files_selected(paths: PoolStringArray) -> void:
	_file_paths = paths

func _on_FileDialog_confirmed() -> void:
	yield($FileDialog, "files_selected") #files_selected() triggers after this, for some reason...
	generate_texture_atlas()


func generate_texture_atlas() -> void:
	var textures = []
	for file_path in _file_paths:
		var texture = load(file_path)
		if texture == null:
			printerr("File not found:", file_path)
			return
		textures.push_back(texture)
	
	var texture_sizes = []
	texture_sizes.resize(textures.size())
	for i in range(textures.size()):
		var texture = textures[i]
		var texture_data = texture.get_data()
		var size = texture_data.get_size()
		texture_sizes[i] = size
	
	var result = Geometry.make_atlas(texture_sizes)
	var points = result.points
	var atlas_size = result.size
	
	var main_atlas_data = Image.new()
	main_atlas_data.create(atlas_size.x, atlas_size.y, true, Image.FORMAT_RGBA8)
	
	for i in range(textures.size()):
		var texture = textures[i]
		var size = texture_sizes[i]
		var position = points[i]
		var texture_data = texture.get_data()
		var texture_rect = Rect2(Vector2(0, 0), size)
		main_atlas_data.blit_rect(texture_data, texture_rect, position)
	
	var main_texture_atlas = ImageTexture.new()
	main_texture_atlas.create_from_image(main_atlas_data)
	ResourceSaver.save(_output_path, main_texture_atlas)
	
	#This ensures that the AtlasTextures store a path to the main texture and not a copy of the data
	main_texture_atlas.take_over_path(_output_path)
	var texture_atlas_ref = load(_output_path)
	
	for i in range(textures.size()):
		var texture = textures[i]
		var size = texture_sizes[i]
		var position = points[i]
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = texture_atlas_ref
		atlas_texture.region = Rect2(position, size)
		
		var file_path = texture.get_path()
		var path = "%s.tres" % file_path.get_basename()
		ResourceSaver.save(path, atlas_texture)
	
	yield(get_tree(), "idle_frame")
	resource_file_system.scan_sources() #Force texture import
