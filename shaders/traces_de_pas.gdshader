shader_type spatial;
render_mode cull_disabled, depth_draw_never;
// Une trace de pas dans la boue (semelle et talon), posée à plat sur le sol. Les UV vont de
// 0 à 1 sur le petit carré ; la pointe du pied est vers V = 0. Mate, à peine visible.

uniform vec3 boue : source_color = vec3(0.085, 0.068, 0.058);
uniform float force = 0.55;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// La semelle (en haut) et le talon (en bas), deux ovales.
	float semelle = length(vec2(p.x / 0.62, (p.y + 0.32) / 0.55));
	float talon = length(vec2(p.x / 0.5, (p.y - 0.55) / 0.36));
	float dedans = 1.0 - smoothstep(0.75, 1.0, min(semelle, talon));
	ALBEDO = boue;
	ROUGHNESS = 1.0;
	SPECULAR = 0.05;
	ALPHA = dedans * force * COLOR.a;
}
