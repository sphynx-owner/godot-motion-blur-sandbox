@tool
class_name BlurGenerator
extends TextureRect


@export var replayer: Replayer

@export var resolution: int = 30

@export var framerate: int = 30

@export var centered: bool = true

@export_tool_button("generate") var generate = _generate


func _generate() -> void:
	var viewport: SubViewport = replayer.get_parent()
	
	var generated_image: Image
	
	var start_position: float = replayer.get_position()
	
	for i in resolution:
		# NOTE @sphynx-owner: resolution - 1 is used to ensure the final position is at
		# the end of the motion, instead of at a subdivision before it. It makes
		# the range of motion captured consistent between reoslutions.
		replayer.seek(start_position + ((i - (float(resolution) / 2.0)) if centered else float(i)) / float(framerate * (resolution - 1)))
		
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		
		(viewport.get_parent() as SubViewportContainer).queue_redraw()
		
		await RenderingServer.frame_post_draw
		
		var viewport_texture: ViewportTexture = viewport.get_texture()
		
		var image: Image = viewport_texture.get_image()
		
		if i == 0:
			generated_image = image
			continue
		
		var image_size: Vector2i = image.get_size()
		
		for j in image_size.x:
			for k in image_size.y:
				generated_image.set_pixel(j, k, (generated_image.get_pixel(j, k) * (i - 1) + image.get_pixel(j, k)) / float(i))
	
	var image_texture: ImageTexture = ImageTexture.create_from_image(generated_image)
	
	texture = image_texture
	
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	
	# HACK @sphynx-skillcap: not sure currently why but this is required
	# to visually reset the replay scene to the start position.
	replayer.seek(start_position)
	replayer.seek(start_position)
