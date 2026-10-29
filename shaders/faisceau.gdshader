shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Le faisceau de lumière dorée au-dessus d'un objet à lire : plus fort en bas, il
// s'efface vers le haut et sur ses bords, avec des voiles qui montent lentement.

uniform vec3 couleur : source_color = vec3(0.95, 0.75, 0.38);
uniform float force = 0.55;

void fragment() {
	float y = 1.0 - UV.y;
	// Plus lumineux face à nous qu'aux bords du tube (effet de volume).
	float face = pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.5);
	float voiles = 0.75 + 0.25 * sin(UV.x * 25.0 + y * 6.0 - TIME * 1.2);
	float fondu = (1.0 - smoothstep(0.0, 1.0, y)) * smoothstep(0.0, 0.06, y);
	ALBEDO = couleur * force * face * voiles * fondu;
}
