shader_type spatial;
render_mode cull_disabled, depth_draw_never;
// Une petite flaque mate dans la boue : un bord irrégulier, une auréole de boue autour, une
// eau sombre qui ne brille presque pas (pas d'effet miroir, demande de Tom).

uniform vec3 boue : source_color = vec3(0.11, 0.088, 0.072);
uniform vec3 eau : source_color = vec3(0.05, 0.05, 0.058);
uniform float graine = 0.0;

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hasard(i), hasard(i + vec2(1.0, 0.0)), u.x),
		mix(hasard(i + vec2(0.0, 1.0)), hasard(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float angle = atan(p.y, p.x);
	// Le bord avance et recule selon l'angle.
	float bord = 0.62 + (bruit(vec2(cos(angle), sin(angle)) * 1.6 + vec2(graine)) - 0.5) * 0.35;
	float r = length(p);
	float dans_eau = 1.0 - smoothstep(bord - 0.05, bord + 0.02, r);
	float aureole = 1.0 - smoothstep(bord, bord + 0.3, r);
	ALBEDO = mix(boue, eau, dans_eau);
	ROUGHNESS = mix(1.0, 0.55, dans_eau);
	SPECULAR = mix(0.05, 0.2, dans_eau);
	ALPHA = max(dans_eau, aureole * 0.7);
}
