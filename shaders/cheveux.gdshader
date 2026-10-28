shader_type spatial;
render_mode cull_disabled;
// Les cheveux longs du héros : on allonge la coiffure du pack (tout ce qui est sous la
// racine descend plus bas) et les pointes balancent avec les mouvements et le vent.
// Le script du héros envoie chaque image la position de la tête et l'« élan » des cheveux.

uniform sampler2D texture_couleur : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 teinte : source_color = vec3(0.12, 0.11, 0.13);
// La racine (sous les oreilles), dans le repère du héros, et la direction du haut de la tête.
uniform vec3 racine = vec3(0.0, 1.62, 0.0);
uniform vec3 haut = vec3(0.0, 1.0, 0.0);
// De combien on allonge les cheveux sous la racine (1 = deux fois plus longs).
uniform float allonge = 1.3;
// Décalage des pointes : le script le calcule avec un léger retard sur les mouvements.
uniform vec3 elan = vec3(0.0);

void vertex() {
	float sous_la_racine = max(dot(racine - VERTEX, haut), 0.0);
	VERTEX -= haut * sous_la_racine * allonge;
	float longueur = sous_la_racine * (1.0 + allonge);
	// Plus on est loin de la racine, plus ça bouge (comme une mèche).
	VERTEX += elan * longueur * longueur * 4.0;
}

void fragment() {
	vec4 couleur = texture(texture_couleur, UV);
	ALBEDO = couleur.rgb * teinte;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
}
