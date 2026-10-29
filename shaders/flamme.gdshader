shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Une flamme dessinée : une forme de goutte qui ondule et se déchire vers le haut, avec un
// cœur jaune pâle, un milieu orange et des pointes rouge sombre. Le plan est toujours
// tourné vers la caméra (mais reste debout), et deux flammes décalées se superposent.

uniform float decalage = 0.0;
uniform float intensite = 1.0;
uniform vec3 couleur_coeur : source_color = vec3(1.0, 0.88, 0.6);
uniform vec3 couleur_milieu : source_color = vec3(0.95, 0.52, 0.18);
uniform vec3 couleur_pointe : source_color = vec3(0.6, 0.14, 0.05);

void vertex() {
	// Toujours face à la caméra, en gardant l'axe vertical du nœud (comme un panneau debout).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], MODEL_MATRIX[1],
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, MODEL_MATRIX[1].xyz)), 0.0), MODEL_MATRIX[3]);
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
		p = p * 2.1 + vec2(5.0, 11.0);
		force *= 0.5;
	}
	return valeur;
}

void fragment() {
	float y = 1.0 - UV.y;
	float t = TIME + decalage;
	// Le feu monte : le bruit défile vers le haut, et ondule plus fort vers les pointes.
	float n = nuages(vec2(UV.x * 3.0 + decalage, y * 2.6 - t * 2.4));
	float x = (UV.x - 0.5) * 2.0 + (n - 0.5) * 0.7 * y;
	// Forme de goutte : arrondie en bas, effilée en haut.
	float largeur = (0.55 + 0.45 * smoothstep(0.0, 0.22, y)) * pow(max(1.0 - y, 0.0), 0.75);
	float forme = 1.0 - smoothstep(largeur * 0.6, largeur, abs(x));
	// Les pointes se déchirent en langues de feu.
	forme *= smoothstep(0.2, 0.42, n + (1.0 - y) * 0.45 - 0.15);
	float chaleur = forme * (1.0 - abs(x) / max(largeur, 0.01)) * (1.0 - y * 0.8);
	vec3 couleur = mix(couleur_pointe, couleur_milieu, smoothstep(0.05, 0.4, chaleur));
	couleur = mix(couleur, couleur_coeur, smoothstep(0.45, 0.85, chaleur));
	ALBEDO = couleur * intensite * forme;
}
