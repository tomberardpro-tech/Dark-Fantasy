shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
// L'eau du ruisseau : sombre et calme, avec de petites rides qui glissent dans le sens
// du courant et un reflet bleuté (la lune) quand on la regarde de biais.
// Les bords sont transparents (couleur des sommets), pour se fondre dans la berge.

uniform vec3 couleur_profonde : source_color = vec3(0.055, 0.071, 0.161);
uniform vec3 couleur_reflet : source_color = vec3(0.247, 0.298, 0.494);
// Vitesse du courant.
uniform float courant = 0.6;

varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// UV.y = distance parcourue le long du ruisseau : les rides avancent avec le courant.
	vec2 p = vec2(UV.x * 3.0, UV.y * 0.8 - TIME * courant);
	float rides = sin(p.y * 4.0 + sin(p.x * 3.0) * 1.5) * 0.5 + sin(p.y * 7.3 - p.x * 2.1 + TIME) * 0.25;
	NORMAL_MAP = normalize(vec3(0.5 + rides * 0.12, 0.5 + rides * 0.08, 1.0));
	float bord = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = mix(couleur_profonde, couleur_reflet, bord * 0.6 + rides * 0.05);
	ROUGHNESS = 0.08;
	METALLIC = 0.2;
	SPECULAR = 0.9;
	ALPHA = COLOR.a * 0.95;
}
