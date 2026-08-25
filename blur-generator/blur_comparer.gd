@tool
extends Control


@export var replayer: Replayer

@export var show_nodes_in_editor: bool = false:
	set(value):
		if replayer:
			replayer.show_nodes_in_editor = value
	
	get():
		if replayer:
			return replayer.show_nodes_in_editor
		
		return false

@export var scene_record: SceneRecord

@export_tool_button("load replay") var load_replay = _load_replay

@export_tool_button("unload replay") var unload_replay = _unload_replay


func _get_configuration_warnings() -> PackedStringArray:
	var ret: PackedStringArray
	
	if !scene_record:
		ret.append("scene record must be set")
	
	return ret


func _load_replay() -> void:
	if !scene_record:
		push_error("no scene record is loaded to replay")
		return
	
	await replayer.load_replay(scene_record)


func _unload_replay() -> void:
	replayer.unload_replay()
