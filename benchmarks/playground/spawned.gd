extends Node3D

var velocity: Vector3

var lifetime: float = 0.0

var lifespan: float = 2

func _ready() -> void:
	velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))


func _process(delta: float) -> void:
	position += velocity * delta
	
	lifetime += delta
	
	if lifetime > lifespan:
		queue_free()
