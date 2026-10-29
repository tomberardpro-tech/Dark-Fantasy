shader_type spatial;
render_mode cull_disabled;
// Une feuille de papier jauni, aux bords plus sombres, couverte de lignes d'écriture
// irrégulières (vue de loin, on devine une lettre).

uniform vec3 papier : source_color = vec3(0.78, 0.7, 0.55);
uniform vec3 encre : source_color = vec3(0.18, 0.13, 0.1);

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec3 couleur = papier * (0.85 + 0.15 * hasard(floor(uv * 40.0)));
	// Les bords jaunis.
	float bord = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	couleur *= mix(0.7, 1.0, smoothstep(0.0, 0.08, bord));
	// Des lignes d'écriture : chaque ligne a une longueur différente, la dernière est courte.
	float ligne = floor(uv.y * 16.0);
	float dans_ligne = fract(uv.y * 16.0);
	float longueur = 0.6 + hasard(vec2(ligne, 3.0)) * 0.3;
	float ecrit = step(0.12, uv.x) * step(uv.x, longueur) * step(1.5, ligne) * step(ligne, 13.0);
	ecrit *= smoothstep(0.35, 0.45, dans_ligne) * (1.0 - smoothstep(0.55, 0.65, dans_ligne));
	ecrit *= step(0.35, hasard(vec2(floor(uv.x * 30.0), ligne)));
	couleur = mix(couleur, encre, ecrit * 0.8);
	ALBEDO = couleur;
	ROUGHNESS = 1.0;
}
