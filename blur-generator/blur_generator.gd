@tool
class_name BlurGenerator
extends Node

enum Directionality{CENTERED, LEADING, TRAILING}

# TODO @sphynx-owner: need a system where a blur generator could handle multiple... Could it be possible
# to have the same generation sequence generate different parameters for different benchmarks? The conditions
# would have to be replicated to individual cameras. Basically, I would have to have the copy prioritize camera
# overrides of environment, attributes, and compositor, and the rest be populated by the environment.
# Then, the blur generator would work directly with each camera. However, it means that I would have to
# have all cameras follow the same position, and share the same world.

# TODO @sphynx-owner: account for centered blur compositor effect. This means that to approximately replicate the
# same motion range, the step would have to be offset by half. Weirdly enough, if non-centered blur is involved, 
# the offset would have to be in the opposite direction to the direction of the blur.
# I would need a separate property for the compositor blur centered-ness, and the centered-ness of the generated
# accumulation blur.

# TODO @sphynx-owner: automatically account for when compositor blur is enabled, and add an additional iteration
# at the start to move from into the first position.

@export var replayer: Replayer

@export var display: GeneratedBlurDisplay

@export_range(1, 1000, 0, "or_greater") var resolution: int = 30

@export var framerate: int = 30

@export var accumulation_directionality: Directionality = Directionality.CENTERED

# TODO @sphynx-owner: consider making this automatically detected.
@export var compositor_blur_enabled: bool = false:
	set(value):
		compositor_blur_enabled = value
		
		notify_property_list_changed()

@export var compositor_blur_directionality: Directionality = Directionality.CENTERED

@export_tool_button("generate") var editor_generate = _editor_generate

var rd: RenderingDevice

var effect: BlurGeneratorCompositor


func _editor_generate() -> void:
	_set_up_compositor()
	generate()


func _ready() -> void:
	rd = RenderingServer.get_rendering_device()


func _validate_property(property: Dictionary) -> void:
	if property.name == "compositor_blur_directionality":
		if !compositor_blur_enabled:
			property.usage &= ~PROPERTY_USAGE_EDITOR


func generate() -> void:
	var viewport: Viewport = replayer.get_viewport()
	
	var start_position: float = replayer.get_position()
	
	effect.current_accumulation = 1
	
	var time_range: float = 1.0 / framerate
	
	var step_size: float = 0.0 if resolution == 1 else time_range / float(resolution - 1)
	
	var time_offset: float
	
	match accumulation_directionality:
		Directionality.CENTERED:
			time_offset = -0.5
		
		Directionality.LEADING:
			time_offset = 0.0
		
		Directionality.TRAILING:
			time_offset = -1.0
	
	var step_offset: float
	
	match compositor_blur_directionality:
		Directionality.CENTERED:
			step_offset = -0.5
		
		Directionality.LEADING:
			step_offset = -1.0
		
		Directionality.TRAILING:
			step_offset = 0.0
	
	var iteration_count: int = (resolution + 1) if compositor_blur_enabled else resolution
	
	for i in iteration_count:
		# HACK @sphynx-owner: for now using this to reset the first frame and ignore it from the accumulation.
		# This is to use motion blurred subframes when accumulating.
		if compositor_blur_enabled and i == 1:
			effect.current_accumulation = 1
		
		# NOTE @sphynx-owner: resolution - 1 is used to ensure the final position is at
		# the end of the motion, instead of at a subdivision before it. It makes
		# the range of motion captured consistent between reoslutions.
		var current_position: float = start_position + time_offset * time_range + (i + step_offset) * step_size
		
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
	
	# HACK @sphynx-skillcap: for some reason, you can get the environment resource and camera
	# attributes from a viewport, but not the compositor. I suspect it is a feature that no
	# one got to implement yet.
	var environment: WorldEnvironment = ReplayUtils.find_environment_recursive(viewport)
	
	if !environment:
		push_error("could not find environment")
		return
	
	if !environment.compositor:
		environment.compositor = Compositor.new()
	
	for compositor_effect in environment.compositor.compositor_effects:
		if compositor_effect is BlurGeneratorCompositor:
			return
	
	environment.compositor.compositor_effects = environment.compositor.compositor_effects + [BlurGeneratorCompositor.new()]
	
	for existing_effect in environment.compositor.compositor_effects:
		if existing_effect is BlurGeneratorCompositor:
			effect = existing_effect


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
	
	if !display.texture or display.texture.get_size() != effect.texture_2d_rd.get_size():
		print("blur generator created new texture")
		
		display.texture = Texture2DRD.new()
		
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
		
		display.texture.texture_rd_rid = temp_texture
		
		# free the old texture if there was one
		if old_texture.is_valid():
			rd.free_rid(old_texture)
	
	rd.texture_copy(effect.texture, RenderingServer.texture_get_rd_texture(display.texture.get_rid()), Vector3.ZERO, Vector3.ZERO, Vector3(tex_size.x, tex_size.y, 1), 0, 0, 0, 0)
