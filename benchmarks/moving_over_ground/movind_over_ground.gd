@tool
extends Node3D


@export var pillar: Node3D

@export_tool_button("generate pillars") var generate_pillars = _generate_pillars

@onready var label: Label = $CanvasLayer/Label


func _generate_pillars() -> void:
	if !pillar:
		push_error("no pillar mesh set")
		return
	
	
	for i in 5:
		var current_position: Vector3 = pillar.global_position + Vector3(i * 10, 0, 0)
		
		while current_position.z > -5000:
			current_position += Vector3(0, 0, -5)
			
			var new_pillar: Node3D = pillar.duplicate()
			
			add_child(new_pillar)
			
			new_pillar.global_position = current_position


func _ready() -> void:
	_generate_pillars()


func _process(delta: float) -> void:
	label.text = "%11.10f|%04d" % [delta, 1.0 / delta]


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			var compositor_effect: GuertinSphynxMotionBlur = EasyCompositorUtils.get_or_add_active_compositor_effect(self, GuertinSphynxMotionBlur)
			
			compositor_effect.enabled = !compositor_effect.enabled
		
		
		if event.keycode == KEY_X and event.pressed:
			var camera_attributes: CameraAttributesPractical = EasyCompositorUtils.get_active_camera_attributes(self)
			
			camera_attributes.motion_blur_enabled = !camera_attributes.motion_blur_enabled
