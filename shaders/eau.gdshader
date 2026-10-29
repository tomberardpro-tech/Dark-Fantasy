shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
// L'eau du ruisseau, avec une vraie matière : le courant fait glisser des veines plus
// claires et plus sombres, la surface ondule (reflets de la lune qui bougent), l'eau est
// plus profonde et sombre au milieu, plus claire au bord (on devine le fond), et une
// mousse blanche cassée s'accroche aux berges.
//
// Le ruban fourni par decor_chemin.gd donne : UV.x de 0 à 1 en travers (l'eau franche
// entre 0,33 et 0,67, les bords qui s'effacent au-delà), UV.y = distance le long du
// ruisseau (en mètres) ; COLOR.a = l'opacité des bords.

uniform vec3 couleur_profonde : source_color = vec3(0.04, 0.055, 0.11);
uniform vec3 couleur_peu_profonde : source_color = vec3(0.11, 0.13, 0.15);
uniform vec3 couleur_reflet : source_color = vec3(0.25, 0.3, 0.48);
uniform vec3 couleur_mousse : source_color = vec3(0.62, 0.66, 0.72);
// Vitesse du courant (mètres par seconde).
uniform float courant = 0.7;

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
		p = p * 2.07 + vec2(13.0, 7.0);
		force *= 0.5;
	}
	return valeur;
}

// La hauteur de la surface : deux couches qui glissent à des vitesses différentes, étirées
// dans le sens du courant (les veines d'une eau qui coule).
float surface(vec2 p) {
	vec2 lent = vec2(p.x * 2.2, p.y * 0.45 - TIME * courant * 0.45);
	vec2 vif = vec2(p.x * 4.5 + 3.0, p.y * 1.1 - TIME * courant);
	return nuages(lent) * 0.6 + nuages(vif) * 0.4;
}

void fragment() {
	// En travers : 0 au milieu de l'eau, 1 au bord de l'eau franche.
	float travers = clamp(abs(UV.x - 0.5) / 0.17, 0.0, 1.6);
	vec2 p = vec2(UV.x * 3.0, UV.y);
	float h = surface(p);
	// La pente de la surface donne l'orientation des reflets.
	float e = 0.04;
	float hx = surface(p + vec2(e, 0.0)) - h;
	float hy = surface(p + vec2(0.0, e)) - h;
	NORMAL_MAP = normalize(vec3(0.5 - hx * 6.0, 0.5 - hy * 6.0, 1.0));
	NORMAL_MAP_DEPTH = 1.0;

	vec3 couleur = mix(couleur_profonde, couleur_peu_profonde, smoothstep(0.35, 1.0, travers));
	// Veines claires et sombres qui glissent avec le courant.
	couleur *= 0.8 + h * 0.45;
	// Le reflet de la lune quand on regarde de biais.
	float biais = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	couleur = mix(couleur, couleur_reflet, biais * 0.5);

	// La mousse : au ras des berges, cassée en petits paquets qui filent avec le courant.
	float paquets = nuages(vec2(UV.x * 9.0, UV.y * 2.2 - TIME * courant * 2.0));
	float mousse = smoothstep(0.75, 1.0, travers + (paquets - 0.5) * 0.5) * (1.0 - smoothstep(1.15, 1.5, travers));
	mousse *= smoothstep(0.42, 0.6, paquets);
	couleur = mix(couleur, couleur_mousse, mousse * 0.7);

	ALBEDO = couleur;
	ROUGHNESS = mix(0.12, 0.8, mousse);
	METALLIC = 0.15;
	SPECULAR = mix(0.75, 0.2, mousse);
	ALPHA = COLOR.a * mix(0.95, 1.0, mousse);
}
