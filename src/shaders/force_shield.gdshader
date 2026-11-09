shader_type canvas_item;

uniform vec4 shield_color : source_color = vec4(0.1, 0.85, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform float scanline_speed : hint_range(0.1, 10.0) = 2.0;
uniform float scanline_density : hint_range(5.0, 80.0) = 30.0;
uniform float edge_intensity : hint_range(0.5, 5.0) = 2.0;
uniform float pulse_speed : hint_range(0.1, 10.0) = 3.0;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	// Borde lateral: 0.0 en el centro, 1.0 en los extremos izquierdo y derecho
	float edge = abs(UV.x - 0.5) * 2.0;
	
	// Líneas de escaneo horizontales desplazándose verticalmente
	float scanline = sin((UV.y - TIME * scanline_speed) * scanline_density) * 0.5 + 0.5;
	
	// Pulso de opacidad energético
	float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
	
	// Mayor intensidad lumínica en los bordes laterales
	float edge_boost = pow(edge, 1.5) * edge_intensity;
	
	// Combinación de color cian neón con bordes y líneas de escaneo brillantes
	vec3 col = mix(shield_color.rgb, edge_color.rgb, clamp(edge_boost * 0.5 + scanline * 0.3, 0.0, 1.0));
	
	// Opacidad combinada con pulso energético y bordes
	float alpha = clamp((base_alpha + edge_boost * 0.35 + scanline * 0.15) * pulse, 0.0, 1.0);
	
	COLOR = vec4(col, alpha * COLOR.a);
}
