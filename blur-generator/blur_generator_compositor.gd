@tool
class_name BlurGeneratorCompositor
extends EnhancedCompositorEffect

const ACCUMULATION_TEXTURE: StringName = "accumulated_color"

var shader_file: RDShaderFile = load("res://blur-generator/blur_generator.glsl")

var current_accumulation: int = 1

var texture_2d_rd := Texture2DRD.new()


func _init():
	context = "BlurGenerator"


func _enhanced_render_callback(render_size: Vector2i):
	ensure_texture(
		ACCUMULATION_TEXTURE,
		RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT,
		render_size,
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	
	texture_2d_rd.texture_rd_rid = get_texture(ACCUMULATION_TEXTURE)
	
	begin_compute()
	
	dispatch_stage(
		shader_file,
		[
			get_sampler_uniform(get_color_texture(), 0),
			get_image_uniform(get_texture(ACCUMULATION_TEXTURE), 1)
		],
		EasyRenderingUtils.get_push_constants([], [current_accumulation]),
		EasyRenderingUtils.get_groups_count(Vector3i(render_size.x, render_size.y, 1), DEFAULT_GROUP_SIZE)
	)
	
	end_compute()
	
	# NOTE @sphynx-owner: imporatnt that the accumulation
	# increments after it's fed to the push constants, otherwise
	# it would always start at 2.
	current_accumulation += 1
