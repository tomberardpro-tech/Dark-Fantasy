shader_type spatial;
// Le sol : une terre brune sombre (plus marron près du feu, plus sombre en forêt), lisse,
// avec seulement de grandes variations très douces (pas de texture, pas de petits points).
// Terre plus chaude autour du feu, clairière un peu plus claire, forêt plus sombre.
// Les passages se fondent sans cercle visible.

uniform vec3 terre_du_feu : source_color = vec3(0.300, 0.220, 0.160);
uniform vec3 herbe_clairiere : source_color = vec3(0.230, 0.195, 0.185);
uniform vec3 sol_foret : source_color = vec3(0.140, 0.125, 0.150);
// Rayons (en mètres) où se font les passages d'une couleur à l'autre.
uniform float fin_de_la_terre = 4.0;
uniform float fin_de_la_clairiere = 9.0;
// Force des variations « peintes » du sol (0 = sol uni).
uniform float variations = 0.15;

varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Un bruit doux : des valeurs au hasard qui se fondent les unes dans les autres.
float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hasard(i), hasard(i + vec2(1.0, 0.0)), u.x),
		mix(hasard(i + vec2(0.0, 1.0)), hasard(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Plusieurs couches de bruit, de la grande tache au petit détail.
float nuages(vec2 p) {
	float valeur = 0.0;
	float force = 0.5;
	for (int k = 0; k < 4; k++) {
		valeur += force * bruit(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		force *= 0.5;
	}
	return valeur;
}

float ondulation(vec2 p) {
	return sin(p.x * 0.9 + 1.3) * cos(p.y * 0.7) * 0.6 + sin(p.x * 0.31 - p.y * 0.47) * 0.9;
}

void fragment() {
	vec2 p = position_monde.xz;
	float r = length(p) + ondulation(p);
	vec3 couleur = mix(herbe_clairiere, sol_foret, smoothstep(fin_de_la_clairiere - 3.0, fin_de_la_clairiere + 2.0, r));
	float r_terre = length(p) + ondulation(p) * 0.4;
	couleur = mix(terre_du_feu, couleur, smoothstep(fin_de_la_terre - 1.8, fin_de_la_terre + 2.2, r_terre));
	// Seulement de grandes taches très douces, comme sur l'image de référence.
	float grandes = nuages(p * 0.08);
	couleur *= 1.0 - variations * 0.5 + grandes * variations;
	ALBEDO = couleur;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
