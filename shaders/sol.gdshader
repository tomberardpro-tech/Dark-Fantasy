shader_type spatial;
// Le sol : les couleurs se fondent doucement, sans cercle visible.
// Terre autour du feu, puis herbe de la clairière, puis sol plus sombre de la forêt.
// Les bords sont irréguliers grâce à de petites ondulations.

uniform vec3 terre_du_feu : source_color = vec3(0.275, 0.220, 0.188);
uniform vec3 herbe_clairiere : source_color = vec3(0.180, 0.239, 0.227);
uniform vec3 sol_foret : source_color = vec3(0.149, 0.200, 0.184);
// Rayons (en mètres) où se font les passages d'une couleur à l'autre.
uniform float fin_de_la_terre = 4.0;
uniform float fin_de_la_clairiere = 9.0;

varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float ondulation(vec2 p) {
	return sin(p.x * 0.9 + 1.3) * cos(p.y * 0.7) * 0.6 + sin(p.x * 0.31 - p.y * 0.47) * 0.9;
}

void fragment() {
	vec2 p = position_monde.xz;
	float r = length(p) + ondulation(p);
	vec3 couleur = mix(herbe_clairiere, sol_foret, smoothstep(fin_de_la_clairiere - 3.0, fin_de_la_clairiere + 2.0, r));
	couleur = mix(terre_du_feu, couleur, smoothstep(fin_de_la_terre - 2.2, fin_de_la_terre + 0.8, r));
	// De légères taches pour que le sol ne soit pas uni.
	couleur *= 0.93 + 0.07 * sin(p.x * 1.7) * cos(p.y * 1.3);
	ALBEDO = couleur;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
