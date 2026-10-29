shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
// Le lit de braises sous les bûches : du charbon noir, fendu de veines orange qui
// rougeoient et respirent doucement. Les bords se fondent dans la terre.

uniform vec3 charbon : source_color = vec3(0.045, 0.036, 0.032);
uniform vec3 rougeoiement : source_color = vec3(1.0, 0.42, 0.1);

varying vec3 position_locale;

void vertex() {
	position_locale = VERTEX;
}

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
	vec2 p = position_locale.xz;
	float r = length(p) / 0.55;
	float n = bruit(p * 9.0) * 0.6 + bruit(p * 21.0) * 0.4;
	// Plus chaud au centre ; chaque veine respire à son rythme.
	float veines = smoothstep(0.5, 0.68, n) * (1.0 - smoothstep(0.2, 1.0, r));
	float souffle = 0.65 + 0.35 * sin(TIME * 1.7 + n * 12.0);
	vec3 couleur = mix(charbon, rougeoiement, veines * souffle);
	ALBEDO = couleur;
	ALPHA = 1.0 - smoothstep(0.75, 1.0, r);
}
