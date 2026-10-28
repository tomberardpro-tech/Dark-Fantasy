shader_type spatial;
// Le bout coupé d'un rondin : du bois plus clair au centre, avec des cernes et une
// fine bordure d'écorce sombre. Les UV vont de -1 à 1 sur le disque.

uniform vec3 bois_clair : source_color = vec3(0.42, 0.32, 0.22);
uniform vec3 bois_fonce : source_color = vec3(0.26, 0.19, 0.13);
uniform vec3 ecorce : source_color = vec3(0.13, 0.10, 0.08);

void fragment() {
	float r = length(UV);
	float angle = atan(UV.y, UV.x);
	// Des cernes un peu irréguliers.
	float cernes = sin((r + sin(angle * 3.0) * 0.02) * 38.0) * 0.5 + 0.5;
	vec3 couleur = mix(bois_clair, bois_fonce, smoothstep(0.3, 0.9, cernes) * 0.6 + r * 0.3);
	// Une petite fente du centre vers le bord.
	float fente = smoothstep(0.03, 0.0, abs(angle - 0.6)) * step(0.15, r) * step(r, 0.8);
	couleur = mix(couleur, bois_fonce * 0.5, fente);
	couleur = mix(couleur, ecorce, smoothstep(0.86, 0.95, r));
	ALBEDO = couleur * 0.75;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
