shader_type canvas_item;

uniform float noise_strength = 0.08;
uniform float glitch_strength = 0.15;

float random_value(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	float noise = random_value(
		floor(uv * vec2(400.0, 250.0)) + floor(TIME * 30.0)
	);
	float scanline = step(
		0.85,
		fract(uv.y * 180.0)
	);
	float glitch_line = step(
		0.96,
		random_value(vec2(floor(TIME * 20.0), floor(uv.y * 35.0)))
	);
	float alpha = noise * noise_strength;
	alpha += scanline * 0.08 * glitch_strength;
	alpha += glitch_line * 0.3 * glitch_strength;
	
	COLOR = vec4(vec3(0.8), min(alpha, 0.5));
}