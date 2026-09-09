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

@export var replayer: Replayer:
	set(value):
		replayer = value
		
		update_configuration_warnings()

@export var use_captured_position: bool = false

@export var captured_position: float = 0

@export_tool_button("capture replay position") var capture_replay_position = _capture_replay_position

@export_tool_button("generate") var editor_generate = _editor_generate

@export var generation_presets: Array[BlurGenerationPreset]:
	set(value):
		generation_presets = value
		
		update_configuration_warnings()

@export var displays: Array[GeneratedBlurDisplay]:
	set(value):
		displays = value
		
		update_configuration_warnings()

var rd: RenderingDevice

#region Tool Button Methods

func _capture_replay_position() -> void:
	assert(replayer.is_replay_loaded(), "replay must be loaded")
	
	captured_position = replayer.get_position()


func _editor_generate() -> void:
	generate_all()

#endregion

#region Virtual Methods

func _ready() -> void:
	rd = RenderingServer.get_rendering_device()


func _get_configuration_warnings() -> PackedStringArray:
	var ret: PackedStringArray
	
	if !replayer:
		ret.append("replayer must be set")
	
	if generation_presets.is_empty():
		ret.append("no generation presets configured")
	
	if generation_presets.size() > displays.size():
		ret.append("not enough displays provided, must at least match the amount of configured generation presets")
	
	return ret

#endregion

#region Public Methods

func generate_all() -> void:
	for i in generation_presets.size():
		var preset: BlurGenerationPreset = generation_presets[i]
		
		if !preset.enabled:
			continue
		
		var display: GeneratedBlurDisplay = displays[i]
		
		await generate(preset, display)


func generate(preset: BlurGenerationPreset, display: GeneratedBlurDisplay) -> void:
	display.preset_name = preset.name
	
	display.copy_environment_from_replay(replayer)
	
	var past_environment: Environment = EasyCompositorUtils.get_active_environment(replayer)
	
	var past_camera_attributes: CameraAttributes = EasyCompositorUtils.get_active_camera_attributes(replayer)
	
	var past_compositor: Compositor = EasyCompositorUtils.get_active_compositor(replayer)
	
	var viewport: Viewport = ReplayUtils.safe_get_viewport(replayer)
	
	# HACK @sphynx-owner: we need the container to force updates to it.
	var viewport_container: SubViewportContainer = viewport.get_parent()
	
	var start_position: float = captured_position if use_captured_position else replayer.get_position()
	
	var time_range: float = 1.0 / preset.framerate
	
	var step_size: float = 0.0 if preset.resolution == 1 else time_range / float(preset.resolution - 1)
	
	var time_offset: float
	
	match preset.accumulation_directionality:
		Directionality.CENTERED:
			time_offset = -0.5
		
		Directionality.LEADING:
			time_offset = 0.0
		
		Directionality.TRAILING:
			time_offset = -1.0
	
	var step_offset: float = 0.0
	
	if preset.custom_compositor:
		match preset.custom_compositor_directionality:
			Directionality.CENTERED:
				step_offset = -0.5
			
			Directionality.LEADING:
				step_offset = -1.0
			
			Directionality.TRAILING:
				step_offset = 0.0
	
	if preset.custom_compositor:
		EasyCompositorUtils.set_active_compositor(replayer, preset.custom_compositor.duplicate(true))
		
	else:
		EasyCompositorUtils.set_active_compositor(replayer, null)
	
	var effect: CompositorEffect = EasyCompositorUtils.get_or_add_active_compositor_effect(replayer, BlurGeneratorCompositor)
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	viewport_container.queue_redraw()
	await RenderingServer.frame_post_draw
	
	effect.current_accumulation = 1
	
	for i in preset.resolution:
		# HACK @sphynx-owner: for now using this to reset the first frame and ignore it from the accumulation.
		# This is to use motion blurred subframes when accumulating.
		if preset.custom_compositor and i == 1:
			effect.current_accumulation = 1
		
		# NOTE @sphynx-owner: resolution - 1 is used to ensure the final position is at
		# the end of the motion, instead of at a subdivision before it. It makes
		# the range of motion captured consistent between reoslutions.
		var current_position: float = start_position + time_offset * time_range + (i + step_offset) * step_size
		
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		
		replayer.seek_rep(current_position)
		
		viewport_container.queue_redraw()
		await RenderingServer.frame_post_draw
	
	_copy_blur_generator_compositor_result(effect, display)
	
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	
	replayer.seek_rep(start_position)
	
	EasyCompositorUtils.set_active_environment(replayer, past_environment)
	EasyCompositorUtils.set_active_camera_attributes(replayer, past_camera_attributes)
	EasyCompositorUtils.set_active_compositor(replayer, past_compositor)

#endregion

#region Private Methods

# HACK @sphynx-owner: using a very elaborate setup to copy the texture over.
# I am probably just incompetent, but using effect.texture_2d_rd.get_image() and
# feeding it to an image texture seems broken, and for me only worked the first time,
# and generated the same image for following generations.
# NOTE @sphynx-owner: I am basically using the same setup from the blur generator
# compositor for generating the render device texture. The only difference is
# the additional required RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT usage flag
func _copy_blur_generator_compositor_result(effect: BlurGeneratorCompositor, display: GeneratedBlurDisplay) -> void:
	var tex_size: Vector2i = effect.texture_2d_rd.get_size()
	
	if !display.texture or Vector2i(display.texture.get_size()) != tex_size:
		var texture_format: RDTextureFormat = rd.texture_get_format(effect.texture_2d_rd.texture_rd_rid)
		
		texture_format.usage_bits |= RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
		
		var new_texture: RID = rd.texture_create(texture_format, RDTextureView.new())
		
		assert(new_texture.is_valid())
		
		var old_texture: RID = display.texture.texture_rd_rid
		
		display.texture.texture_rd_rid = new_texture
		
		# free the old texture if there was one
		if old_texture.is_valid():
			rd.free_rid(old_texture)
	
	rd.texture_copy(effect.texture_2d_rd.texture_rd_rid, display.texture.texture_rd_rid, Vector3.ZERO, Vector3.ZERO, Vector3(tex_size.x, tex_size.y, 1), 0, 0, 0, 0)

#endregion
