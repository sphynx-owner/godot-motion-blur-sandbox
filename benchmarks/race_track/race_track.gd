extends Node3D

@export var speed: float = 300.0

@onready var label: Label = $CanvasLayer/Label


func set_speed(value: float) -> void:
	speed = value


func get_speed() -> float:
	return speed


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	%PathFollow3D.progress += delta * speed
	
	label.text = "%11.10f|%04d" % [delta, 1.0 / delta]


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			var compositor_effect: GuertinSphynxMotionBlur = EasyCompositorUtils.get_or_add_active_compositor_effect(self, GuertinSphynxMotionBlur)
			
			compositor_effect.enabled = !compositor_effect.enabled
