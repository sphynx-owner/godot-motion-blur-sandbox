@tool
extends Node3D


@export var pillar: Node3D


@export_tool_button("generate pillars") var generate_pillars = _generate_pillars


func _generate_pillars() -> void:
	if !pillar:
		push_error("no pillar mesh set")
		return
	
	var current_position: Vector3 = pillar.global_position
	
	while current_position.z > -5000:
		current_position += Vector3(0, 0, -5)
		
		var new_pillar: Node3D = pillar.duplicate()
		
		add_child(new_pillar)
		
		new_pillar.global_position = current_position


func _ready() -> void:
	_generate_pillars()
