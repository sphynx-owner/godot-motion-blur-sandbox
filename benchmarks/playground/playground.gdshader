shader_type spatial;

render_mode world_vertex_coords, cull_disabled, depth_draw_always;

uniform bool use_clip;

uniform sampler2D color_texture: source_color;

varying vec3 vertex_position;

void vertex() {
	vertex_position = VERTEX;
}

void fragment() {
	vec4 color = texture(color_texture, vertex_position.xz);
	
	ALBEDO = texture(color_texture, vertex_position.xz).rgb;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = texture(color_texture, vertex_position.xz).a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
