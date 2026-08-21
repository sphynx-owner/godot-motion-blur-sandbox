@tool
class_name FullScreenQuad
extends MeshInstance3D

const shader: Shader = preload("res://screen_quad.gdshader")

var texture: Texture2D:
	set(value):
		material_override.set_shader_parameter("color", value)
	
	get():
		return material_override.get_shader_parameter("color")


func _ready() -> void:
	mesh = QuadMesh.new()
	
	material_override = ShaderMaterial.new()
	
	material_override.shader = shader
	
	custom_aabb = AABB(Vector3(-10000, -10000, -10000), Vector3(20000, 20000, 20000))
