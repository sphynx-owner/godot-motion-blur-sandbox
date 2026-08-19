@tool
class_name BlurGenerator
extends TextureRect

@export var replayer: Replayer

@export var resolution: int = 30

@export var framerate: int = 30

@export var centered: bool = true

var rd: RenderingDevice

var effect: BlurGeneratorCompositor


func _ready() -> void:
	rd = RenderingServer.get_rendering_device()
	
	_set_up_compositor()


func generate() -> void:
	var viewport: Viewport = replayer.get_viewport()
	
	var start_position: float = replayer.get_position()
	
	effect.current_accumulation = 1
	
	for i in resolution:
		# NOTE @sphynx-owner: resolution - 1 is used to ensure the final position is at
		# the end of the motion, instead of at a subdivision before it. It makes
		# the range of motion captured consistent between reoslutions.
		var current_position: float = start_position + ((i - (float(resolution - 1) / 2.0)) if centered else float(i)) / float(framerate * (resolution - 1))
		
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		
		# HACK @sphynx-owner: seeking twice to force an update.
		replayer.seek_rep(current_position)
		replayer.seek_rep(current_position)
		
		await RenderingServer.frame_post_draw
	
	_copy_texture()
	
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	
	# HACK @sphynx-owner: seeking twice to force an update.
	replayer.seek_rep(start_position)
	replayer.seek_rep(start_position)


func _set_up_compositor() -> void:
	var viewport: Viewport = replayer.get_viewport()
	
	var camera: Camera3D
	
	for child in viewport.get_children():
		if child is Camera3D:
			camera = child
			break
	
	if !camera:
		push_error("could not find camera")
		return
	
	if !camera.compositor:
		camera.compositor = Compositor.new()
	
	for compositor_effect in camera.compositor.compositor_effects:
		if compositor_effect is BlurGeneratorCompositor:
			return
	
	camera.compositor.compositor_effects = camera.compositor.compositor_effects + [BlurGeneratorCompositor.new()]
	
	effect = camera.compositor.compositor_effects[0]


# HACK @sphynx-skillcap: using a very elaborate setup to copy the texture over.
# I am probably just incompetent, but using effect.texture_2d_rd.get_image() and
# feeding it to an image texture seems broken, and for me only worked the first time,
# and generated the same image for following generations.
# NOTE @sphynx-skillcap: I am basically using the same setup from the blur generator
# compositor for generating the render device texture. The only difference is
# the additional required RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT usage flag
func _copy_texture() -> void:
	var tex_size: Vector2i = effect.texture_2d_rd.get_size()
	
	var temp_texture: RID
	
	if !texture or texture.get_size() != effect.texture_2d_rd.get_size():
		print("blur generator created new texture")
		
		texture = Texture2DRD.new()
		
		var texture_format := RDTextureFormat.new()
		
		# create our output texture
		texture_format = RDTextureFormat.new()
		texture_format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
		texture_format.width = tex_size.x
		texture_format.height = tex_size.y
		texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
		texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
		
		var new_texture = rd.texture_create(texture_format, RDTextureView.new())
		
		assert(new_texture.is_valid())
		
		var old_texture: RID = temp_texture
		
		temp_texture = RID()
		
		# save the new texture rid
		temp_texture = new_texture
		
		# HACK: We wait with both releasing the old texture, and replacing the
		# texture_rd_rid, since it seems to clash with godot's rendering pipeline otherwise
		await RenderingServer.frame_post_draw
		
		texture.texture_rd_rid = temp_texture
		
		# free the old texture if there was one
		if old_texture.is_valid():
			rd.free_rid(old_texture)
	
	rd.texture_copy(effect.texture, RenderingServer.texture_get_rd_texture(texture.get_rid()), Vector3.ZERO, Vector3.ZERO, Vector3(tex_size.x, tex_size.y, 1), 0, 0, 0, 0)
