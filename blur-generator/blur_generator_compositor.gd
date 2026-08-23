@tool
class_name BlurGeneratorCompositor
extends EnhancedCompositorEffect

var shader_file: RDShaderFile = load("res://blur-generator/blur_generator.glsl")

var current_accumulation: int = 1

var texture: RID
var texture_2d_rd := Texture2DRD.new()


func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		if !rd_instance.is_valid():
			return
		
		if texture.is_valid():
			rd_instance.rd.free_rid(texture)



func _init():
	context = "BlurGenerator"


func _enhanced_render_callback(render_size: Vector2i):
	var texture_is_ready: bool = texture_2d_rd.texture_rd_rid.is_valid()
	
	if texture_is_ready:
		var format: RDTextureFormat = rd_instance.rd.texture_get_format(texture_2d_rd.texture_rd_rid)
		
		if format.width != render_size.x or format.height != render_size.y:
			texture_is_ready = false
	
	if !texture_is_ready:
		_build_texture(render_size)
	
	dispatch_stage(
		shader_file,
		[
			get_sampler_uniform(get_color_texture(), 0),
			get_image_uniform(texture, 1)
		],
		get_push_constants([], [current_accumulation]),
		get_groups_count(Vector3i(render_size.x, render_size.y, 1), DEFAULT_GROUP_SIZE),
		"Blur Generation"
	)
	
	# NOTE @sphynx-owner: imporatnt that the accumulation
	# increments after it's fed to the push constants, otherwise
	# it would always start at 2.
	current_accumulation += 1


# fetched from https://github.com/dmlary/godot-demo-sencil-buffer-compositor-effect
## Create a new color texture to use as the output for our render pipeline.
## Note: this texture must be the same size as the color texture, so we create
## it on demand.
func _build_texture(size: Vector2i):
	var texture_format := RDTextureFormat.new()
	
	# create our output texture
	texture_format = RDTextureFormat.new()
	texture_format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	texture_format.width = size.x
	texture_format.height = size.y
	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var new_texture = rd_instance.rd.texture_create(texture_format, RDTextureView.new())
	
	assert(new_texture.is_valid())
	
	var old_texture: RID = texture_2d_rd.texture_rd_rid
	
	# HACK @sphynx-skillcap: the new texture must be set into an RID variable,
	# seems to get freed otherwise even if fed into a texture_rd_rid variable of a Texture2DRD
	texture = new_texture
	
	# HACK: We wait with both releasing the old texture, and replacing the
	# texture_rd_rid, since it seems to clash with godot's rendering pipeline otherwise
	await RenderingServer.frame_post_draw
	
	texture_2d_rd.texture_rd_rid = new_texture
	
	# free the old texture if there was one
	if old_texture.is_valid():
		rd_instance.rd.free_rid(old_texture)
