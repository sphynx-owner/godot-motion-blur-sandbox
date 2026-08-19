@tool
class_name FullScreenQuad
extends MeshInstance3D

const shader: Shader = preload("res://screen_quad.gdshader")


func _ready() -> void:
	material_override = ShaderMaterial.new()
	
	material_override.shader = shader
	
	custom_aabb = AABB(Vector3(-10000, -10000, -10000), Vector3(20000, 20000, 20000))
