@tool
extends Control


@export var replayer: Replayer


@export_tool_button("load replay") var load_replay = _load_replay

@export_tool_button("unload replay") var unload_replay = _unload_replay


func _load_replay() -> void:
	await replayer.load_replay(load("res://addons/sphynx-replay-tool/temp/temp_scene_record.tres"))


func _unload_replay() -> void:
	replayer.unload_replay()
