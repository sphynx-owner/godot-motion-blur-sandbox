shader_type spatial;
render_mode skip_vertex_transform, unshaded;

uniform sampler2D color: source_color;

void vertex() {
	VERTEX = (INV_PROJECTION_MATRIX * vec4(VERTEX * vec3(-2.0, 2.0, 1.0), 1.0)).xyz;
}

void fragment() {
	ALBEDO = texture(color, SCREEN_UV).rgb;
}
