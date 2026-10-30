shader_type spatial;
render_mode cull_disabled;
// Le sentier de terre battue : plus clair et tassé au milieu (là où l'on marche), des bords
// irréguliers où la forêt reprend sa place, de la boue dans les creux et près du ruisseau,
// et quelques flaques sombres (mates : pas d'effet miroir).
//
// Le ruban fourni par decor_chemin.gd donne :
//   UV.x  = la distance au milieu du sentier, en demi-largeurs (bord théorique à ±1) ;
//   COLOR.r = l'humidité (1 près du ruisseau) ; COLOR.a = l'apparition au départ.

uniform vec3 terre : source_color = vec3(0.272, 0.222, 0.193);
uniform vec3 terre_tassee : source_color = vec3(0.33, 0.27, 0.226);
uniform vec3 boue : source_color = vec3(0.122, 0.094, 0.075);
uniform vec3 flaque : source_color = vec3(0.065, 0.060, 0.062);

varying vec3 position_monde;
varying float humidite;
varying float apparition;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	humidite = COLOR.r;
	apparition = COLOR.a;
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

void fragment() {
	vec2 p = position_monde.xz;
	float ecart = abs(UV.x);
	// Le bord avance et recule : grandes ondulations et petites touffes qui mordent.
	float bord = 1.0 + (nuages(p * 0.45) - 0.5) * 0.8 + (bruit(p * 3.1) - 0.5) * 0.25;
	float opacite = 1.0 - smoothstep(bord - 0.3, bord + 0.12, ecart);

	// Terre tassée au milieu, plus sombre vers les bords.
	vec3 couleur = mix(terre_tassee, terre, smoothstep(0.1, 0.8, ecart));
	couleur *= 0.9 + nuages(p * 0.6) * 0.2;

	// La boue : dans les creux (grandes taches) et partout près de l'eau.
	float creux = smoothstep(0.58, 0.72, nuages(p * 0.16 + vec2(4.0, 1.0)));
	float mouille = clamp(max(creux * 0.75, humidite), 0.0, 1.0);
	couleur = mix(couleur, boue, mouille);

	// Les flaques : seulement au cœur des zones boueuses, vers le milieu du sentier.
	float trou = nuages(p * 0.55 + vec2(9.0, 3.0));
	float dans_flaque = smoothstep(0.62, 0.66, trou) * smoothstep(0.35, 0.7, mouille) * (1.0 - smoothstep(0.45, 0.75, ecart));
	couleur = mix(couleur, flaque, dans_flaque);

	ALBEDO = couleur;
	ROUGHNESS = mix(1.0, 0.6, dans_flaque);
	SPECULAR = mix(0.1, 0.25, dans_flaque);
	ALPHA = opacite * apparition;
}
