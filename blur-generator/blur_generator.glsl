#[compute]
#version 450

#define FLT_MAX 3.402823466e+38
#define FLT_MIN 1.175494351e-38

// A samplre to Godot's color texture
layout(set = 0, binding = 0) uniform sampler2D color_sampler;
// An output image we created for this
layout(rgba32f, set = 0, binding = 1) uniform image2D average_output;

layout(push_constant, std430) uniform Params 
{
	int accum_count;
	int nan2;
	int nan3;
	int nan4;
} params;

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

void main() 
{
	// Get the size of the color sampler image, equivalent to render size
	ivec2 render_size = ivec2(textureSize(color_sampler, 0));

	// Get the pixel we are in
	ivec2 uvi = ivec2(gl_GlobalInvocationID.xy);

	// If this pixel is outside the image, return
	if ((uvi.x >= render_size.x) || (uvi.y >= render_size.y)) 
	{
		return;
	}

	// Feed the final position into our output position texture
	imageStore(average_output, uvi, (imageLoad(average_output, uvi) * (params.accum_count - 1) + vec4(texelFetch(color_sampler, uvi, 0).rgb, 1.0)) / params.accum_count);//vec4(texelFetch(color_sampler, uvi, 0).rgb, 1.0));//
}
