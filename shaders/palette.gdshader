shader_type canvas_item;
// Palette commune : chaque pixel de l'image est ramené à la couleur la plus proche
// de la palette du jeu (bleus nuit, violets, verts éteints, bois, feu, rouge maudit).
// Un léger tramage (motif régulier de points) adoucit le passage entre deux couleurs.

uniform bool palette_active = true;
// Force du tramage : 0 = aucun, plus grand = plus visible.
uniform float tramage = 0.055;

const vec3 PALETTE[26] = vec3[26](
	vec3(0.027, 0.035, 0.102), // #07091a nuit profonde
	vec3(0.055, 0.071, 0.161), // #0e1229
	vec3(0.086, 0.110, 0.227), // #161c3a
	vec3(0.125, 0.157, 0.302), // #20284d
	vec3(0.176, 0.220, 0.388), // #2d3863
	vec3(0.247, 0.298, 0.494), // #3f4c7e
	vec3(0.357, 0.416, 0.620), // #5b6a9e
	vec3(0.525, 0.588, 0.761), // #8696c2 brume
	vec3(0.765, 0.804, 0.902), // #c3cde6 lune
	vec3(0.933, 0.941, 0.965), // #eef0f6
	vec3(0.137, 0.102, 0.208), // #231a35 violets
	vec3(0.227, 0.165, 0.322), // #3a2a52
	vec3(0.353, 0.263, 0.467), // #5a4377
	vec3(0.094, 0.129, 0.122), // #18211f végétation éteinte
	vec3(0.149, 0.200, 0.184), // #26332f
	vec3(0.227, 0.290, 0.263), // #3a4a43
	vec3(0.337, 0.396, 0.357), // #56655b
	vec3(0.165, 0.133, 0.122), // #2a221f bois et terre
	vec3(0.275, 0.220, 0.188), // #463830
	vec3(0.392, 0.329, 0.290), // #64544a
	vec3(0.604, 0.294, 0.149), // #9a4b26 feu
	vec3(0.816, 0.478, 0.208), // #d07a35
	vec3(0.941, 0.678, 0.333), // #f0ad55
	vec3(1.000, 0.878, 0.627), // #ffe0a0
	vec3(0.369, 0.102, 0.141), // #5e1a24 rouge de la malédiction
	vec3(0.690, 0.188, 0.227)  // #b0303a
);

float bayer2(vec2 a) {
	a = floor(a);
	return fract(a.x * 0.5 + a.y * a.y * 0.75);
}

float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	if (palette_active) {
		// Le tramage suit les gros pixels du jeu, pas les pixels de l'écran.
		vec2 pixel = floor(UV / TEXTURE_PIXEL_SIZE);
		c += (bayer4(pixel) - 0.5) * tramage;
		vec3 meilleure = PALETTE[0];
		float ecart_min = 1e9;
		for (int i = 0; i < 26; i++) {
			vec3 d = c - PALETTE[i];
			float ecart = dot(d * d, vec3(0.3, 0.59, 0.11));
			if (ecart < ecart_min) {
				ecart_min = ecart;
				meilleure = PALETTE[i];
			}
		}
		c = meilleure;
	}
	COLOR = vec4(c, 1.0);
}
