extends MeshInstance3D


func _process(delta: float) -> void:
	var time: float = Time.get_ticks_msec() / 1000.0
	
	position.x = sin(time * 8) * 40
