tool
extends EditorPlugin

var _dock: Control = null

func _enter_tree() -> void:
	_dock = preload("dock.tscn").instance()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _dock)
	
	_dock.resource_file_system = get_editor_interface().get_resource_filesystem()

func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	_dock.free()
