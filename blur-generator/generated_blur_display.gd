@tool
class_name GeneratedBlurDisplay
extends SubViewportContainer

@export var replayer: Replayer

@export_tool_button("copy environment") var ed_copy_environment = copy_environment

var texture: Texture2D:
	set(value):
		if !_full_screen_quad:
			push_error("trying to set texture of blur display but missing full screen quad")
			return
		
		_full_screen_quad.texture = value
	
	get():
		if !_full_screen_quad:
			push_error("trying to get texture of blur display but missing full screen quad")
			return null
		
		return _full_screen_quad.texture

var _viewport: SubViewport

var _camera: Camera3D

var _full_screen_quad: FullScreenQuad


func clear_environment() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	_viewport = null
	
	_camera = null
	
	_full_screen_quad = null


func copy_environment() -> void:
	assert(replayer and replayer.is_replay_loaded(), "replayer must be set and loaded to copy the environment from")
	
	var ref_viewport: SubViewport = replayer.get_viewport()
	
	var ref_camera: Camera3D = ref_viewport.get_camera_3d()
	
	var ref_environment: WorldEnvironment = ReplayUtils.find_environment_recursive(ref_viewport)
	
	var new_viewport: SubViewport = ref_viewport.duplicate()
	
	new_viewport.own_world_3d = true
	
	add_child(new_viewport)
	
	var new_camera: Camera3D = ref_camera.duplicate()
	
	# NOTE @sphynx-owner: these properties are equivalent on the _camera and the environment,
	# but the ones on the _camera take precedence. Since we are only recreating the environment
	# using _camera nodes on the displays, we just want to emulate the same conditions using
	# said cameras.
	# ----------------------------------
	if !new_camera.environment:
		new_camera.environment = ref_environment.environment
	
	if !new_camera.attributes:
		new_camera.attributes = ref_environment.camera_attributes
	
	if !new_camera.compositor:
		new_camera.compositor = ref_environment.compositor
	# ----------------------------------
	
	new_viewport.add_child(new_camera)
	
	_full_screen_quad = FullScreenQuad.new()
	
	add_child(_full_screen_quad)
