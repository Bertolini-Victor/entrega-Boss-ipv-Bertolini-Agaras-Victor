shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.82, 0.2, 1.0);
uniform float speed : hint_range(0.1, 10.0) = 3.5;
uniform float pulse_intensity : hint_range(0.0, 2.0) = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Pulso de energía dorado/amarillo cálido usando sin(TIME * speed)
	float pulse = 0.5 + 0.5 * sin(TIME * speed);
	
	// Iluminar suavemente los píxeles del orbe
	vec3 colored = tex.rgb * glow_color.rgb * (1.0 + pulse * pulse_intensity);
	vec3 additive_glow = glow_color.rgb * (pulse * 0.3 * tex.a);
	
	COLOR = vec4(colored + additive_glow, tex.a);
}
