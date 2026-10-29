shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
// L'eau du ruisseau, sombre et calme (choix de Tom) : presque noire et bleutée, un courant
// lent, et des reflets de lune qui ondulent. Le relief des rides vient de deux textures de
// vagues (fabriquées par decor_chemin.gd) qui glissent l'une sur l'autre, à des tailles et
// des vitesses différentes : c'est ce qui fait bouger les reflets naturellement.
//
// Le ruban fourni par decor_chemin.gd donne : UV.x de 0 à 1 en travers (l'eau franche
// entre 0,33 et 0,67, les bords qui s'effacent au-delà), UV.y = distance le long du
// ruisseau (en mètres) ; COLOR.a = l'opacité des bords.

uniform sampler2D vagues_larges : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D vagues_fines : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec3 couleur_profonde : source_color = vec3(0.018, 0.026, 0.05);
uniform vec3 couleur_bord : source_color = vec3(0.05, 0.06, 0.075);
uniform vec3 couleur_lune : source_color = vec3(0.32, 0.38, 0.55);
// Vitesse du courant (mètres par seconde).
uniform float courant = 0.25;
// Force du relief des rides.
uniform float relief = 0.7;

void fragment() {
	// Coordonnées en mètres : en travers (le ruban fait environ 3,6 m) et le long du courant.
	vec2 p = vec2(UV.x * 3.6, UV.y);
	vec3 a = texture(vagues_larges, p * 0.18 + vec2(0.0, -TIME * courant * 0.18)).rgb;
	vec3 b = texture(vagues_fines, p * 0.55 + vec2(0.37, -TIME * courant * 0.55 * 1.3)).rgb;
	NORMAL_MAP = normalize(a * 2.0 - 1.0 + b * 2.0 - 1.0) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = relief;

	// En travers : 0 au milieu de l'eau, 1 au bord de l'eau franche.
	float travers = clamp(abs(UV.x - 0.5) / 0.17, 0.0, 1.6);
	vec3 couleur = mix(couleur_profonde, couleur_bord, smoothstep(0.5, 1.2, travers));
	// Le reflet bleuté de la lune quand on regarde de biais (il suit les rides).
	float biais = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	couleur = mix(couleur, couleur_lune, biais * 0.45);
	// Un soupçon d'écume contre les berges, à peine visible.
	float ecume = smoothstep(0.92, 1.05, travers + (b.r - 0.5) * 0.25) * (1.0 - smoothstep(1.1, 1.4, travers));
	couleur = mix(couleur, vec3(0.42, 0.45, 0.5), ecume * 0.25);

	ALBEDO = couleur;
	ROUGHNESS = mix(0.04, 0.5, ecume);
	METALLIC = 0.0;
	SPECULAR = 0.7;
	ALPHA = COLOR.a * 0.97;
}
