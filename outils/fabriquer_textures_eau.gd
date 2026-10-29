extends SceneTree
## Outil (à lancer une fois, sans fenêtre) : fabrique les deux textures de relief de l'eau du
## ruisseau (rides sans couture) dans assets/eau/. Commande :
## Godot --headless --path . --script outils/fabriquer_textures_eau.gd
func _initialize() -> void:
	_lancer.call_deferred()
func _texture(bruit: FastNoiseLite, force: float, fichier: String) -> void:
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.seamless_blend_skirt = 0.2
	t.as_normal_map = true
	t.bump_strength = force
	t.noise = bruit
	await t.changed
	var img := t.get_image()
	img.save_png(ProjectSettings.globalize_path(fichier))
	print("ENREGISTRE ", fichier, " ", img.get_size())
func _lancer() -> void:
	var larges := FastNoiseLite.new()
	larges.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	larges.frequency = 0.008
	larges.fractal_type = FastNoiseLite.FRACTAL_FBM
	larges.fractal_octaves = 4
	larges.seed = 3
	await _texture(larges, 10.0, "res://assets/eau/vagues_larges.png")
	var fines := FastNoiseLite.new()
	fines.noise_type = FastNoiseLite.TYPE_CELLULAR
	fines.frequency = 0.02
	fines.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	fines.fractal_type = FastNoiseLite.FRACTAL_FBM
	fines.fractal_octaves = 2
	fines.seed = 8
	await _texture(fines, 6.0, "res://assets/eau/vagues_fines.png")
	quit()
