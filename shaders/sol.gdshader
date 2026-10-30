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
// Texture de la terre (essai demandé par Tom) : mottes et grain, mats. 0 = sol lisse.
uniform float texture_terre = 0.5;
// Le sol de Bruneval, dans l'enceinte : une terre tassée par les pas, un peu plus claire
// et plus chaude que la forêt, plus sombre le long de la palissade. Réglé par bruneval.gd
// (l'ovale de la clairière, en mètres « comme à l'écran ») ; sans réglage, rien ne change.
uniform vec3 terre_village : source_color = vec3(0.205, 0.172, 0.150);
uniform vec2 village_origine = vec2(0.0, 0.0);
uniform vec2 village_droite = vec2(1.0, 0.0);
uniform vec2 village_haut = vec2(0.0, 1.0);
uniform vec2 village_demi = vec2(0.0, 0.0);
uniform float village_centre_y = 0.0;

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
	// Bruneval : la terre tassée de l'enceinte (bord un peu irrégulier, fondu doux),
	// plus sombre en s'approchant de la palissade.
	if (village_demi.x > 0.0) {
		vec2 d = p - village_origine;
		vec2 v = vec2(dot(d, village_droite), dot(d, village_haut) - village_centre_y);
		float e = length(v / village_demi) + (nuages(p * 0.35) - 0.5) * 0.12;
		vec3 enceinte = mix(terre_village, terre_village * 0.72, smoothstep(0.55, 0.98, e));
		enceinte *= 0.94 + nuages(p * 0.22 + vec2(5.0, 2.0)) * 0.12;
		couleur = mix(couleur, enceinte, 1.0 - smoothstep(0.96, 1.1, e));
	}
	// Seulement de grandes taches très douces, comme sur l'image de référence.
	float grandes = nuages(p * 0.08);
	couleur *= 1.0 - variations * 0.5 + grandes * variations;
	// Des mottes de terre (environ 70 cm) et un grain plus fin (environ 25 cm), sans relief
	// ni brillance : seulement des nuances de couleur.
	float mottes = nuages(p * 1.4 + vec2(31.0, 7.0));
	float grain = bruit(p * 4.0 + vec2(3.0, 19.0));
	couleur *= 1.0 + ((mottes - 0.5) * 0.3 + (grain - 0.5) * 0.14) * texture_terre;
	ALBEDO = couleur;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
