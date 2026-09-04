extends Camera3D

@export var speed: float = 50.0


func _process(delta: float) -> void:
	position.z += -delta * speed
	
	if position.z < -4000:
		position.z = 0


func set_height(value: float) -> void:
	position.y = value


func get_height() -> float:
	return position.y


func set_speed(value: float) -> void:
	speed = value


func get_speed() -> float:
	return speed


func set_rotation_y(value: float) -> void:
	rotation.y = -value


func get_rotation_y() -> float:
	return -rotation.y


func set_rotation_x(value: float) -> void:
	rotation.x = -value


func get_rotation_x() -> float:
	return -rotation.x
