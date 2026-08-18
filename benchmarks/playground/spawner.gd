extends Node3D

const SceneToSpawn: PackedScene = preload("res://benchmarks/playground/spawned.tscn")

@export var timer: Timer


func _ready() -> void:
	timer.timeout.connect(_on_timeout)


func _on_timeout() -> void:
	var new_spawned: Node3D = SceneToSpawn.instantiate()
	
	get_parent().add_child(new_spawned)
	
	new_spawned.position = position
