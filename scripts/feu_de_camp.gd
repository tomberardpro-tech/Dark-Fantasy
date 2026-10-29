extends Node3D
## Feu de camp, animé comme sur la maquette : un cercle de galets, des bûches d'écorce
## noircie sur un lit de braises qui rougeoient,
## des flammes en particules (jaunes au cœur, rouges en montant), une fumée sombre, des braises qui montent en tourbillonnant,
## et une lumière orange qui tremble.
## Le vent (voir vent.gd) couche les flammes et emporte les braises.

## Puissance de la lumière du feu.
@export var puissance := 6.0
## Distance éclairée par le feu (en mètres).
@export var portee := 16.0
## Vitesse à laquelle la lumière baisse en s'éloignant du feu : plus c'est petit,
## plus le halo orange est large et doux (comme sur la maquette).
@export var baisse := 1.2
## Nombre de braises qui s'envolent.
@export var nombre_braises := 40

const GALETS := ["Pebble_Round_1", "Pebble_Round_2", "Pebble_Round_3", "Pebble_Round_4", "Pebble_Round_5"]

var _flammes: Array[CPUParticles3D] = []
var _support_flammes: Node3D
var _lumiere: OmniLight3D
var _braises: MultiMesh
var _vie_braises: Array[float] = []
var _temps := 0.0


func _ready() -> void:
	_creer_pierres()
	_creer_buches()
	_creer_flammes()
	_creer_braises()
	_creer_obstacle()
	# Le crépitement du feu, qu'on entend en s'approchant.
	Sons.boucle("feu", self, -6.0, 12.0)
	_lumiere = OmniLight3D.new()
	_lumiere.light_color = Color("e0823a")
	_lumiere.light_energy = puissance
	_lumiere.omni_range = portee
	_lumiere.omni_attenuation = baisse
	_lumiere.shadow_enabled = true
	_lumiere.position.y = 1.1
	add_child(_lumiere)


func _process(delta: float) -> void:
	_temps += delta
	var vent := Vent.souffle(_temps, global_position)
	# Plusieurs vagues mélangées pour un vacillement qui ne semble pas répétitif.
	var v := 0.85 + sin(_temps * 13.0) * 0.08 + sin(_temps * 7.3) * 0.07 + sin(_temps * 23.0) * 0.04
	_lumiere.light_energy = puissance * v
	# Le vent emporte les flammes et la fumée (la fumée, plus légère, beaucoup plus).
	for i in _flammes.size():
		var force := 2.5 if i == _flammes.size() - 1 else 0.8
		_flammes[i].gravity = Vector3(vent.x * force, _flammes[i].gravity.y, vent.z * force)
	_animer_braises(delta)


func _creer_pierres() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		var a := TAU * i / 9.0
		var galet := (load("res://assets/nature/" + GALETS[i % GALETS.size()] + ".gltf") as PackedScene).instantiate() as Node3D
		galet.position = Vector3(cos(a) * 0.78, 0.0, sin(a) * 0.78)
		galet.rotation.y = rng.randf_range(0.0, TAU)
		galet.scale = Vector3(0.75, 2.2, 0.75)
		add_child(galet)
		for maillage in galet.find_children("*", "MeshInstance3D", true, false):
			maillage.material_override = _materiau(Color("5d6372"))


func _creer_buches() -> void:
	# L'écorce des arbres du pack, noircie par le feu.
	var mat := _materiau(Color(0.32, 0.27, 0.25))
	mat.albedo_texture = load("res://assets/nature/Bark_NormalTree.png")
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/nature/Bark_NormalTree_Normal.png")
	mat.uv1_scale = Vector3(1.0, 2.0, 1.0)
	for i in 4:
		var forme := CylinderMesh.new()
		forme.top_radius = 0.09
		forme.bottom_radius = 0.11
		forme.height = 1.1
		forme.radial_segments = 6
		var buche := MeshInstance3D.new()
		buche.mesh = forme
		buche.material_override = mat
		buche.rotation = Vector3(0.0, i * PI / 4.0, PI / 2.0 - 0.35)
		buche.position.y = 0.2
		add_child(buche)


func _creer_flammes() -> void:
	# Des particules (comme dans la plupart des jeux) : chaque langue de feu naît à la base,
	# monte en tremblant, passe du jaune au rouge en rétrécissant, et s'éteint.
	_support_flammes = Node3D.new()
	_support_flammes.position.y = 0.15
	add_child(_support_flammes)
	var tache := _tache_douce()
	# [nombre, durée de vie, taille, vitesse, couleurs (du début à la fin)]
	var couches := [
		[46, 0.8, 0.5, 1.1, [Color(1.0, 0.85, 0.5, 0.9), Color(1.0, 0.55, 0.18, 0.8), Color(0.75, 0.18, 0.05, 0.5), Color(0.25, 0.05, 0.02, 0.0)]],
		[22, 0.45, 0.32, 0.8, [Color(1.0, 0.97, 0.8, 1.0), Color(1.0, 0.8, 0.4, 0.8), Color(1.0, 0.5, 0.15, 0.0)]],
	]
	for c in couches:
		var feu := _particules(c[0], c[1], c[2], tache, c[4], true)
		feu.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		feu.emission_sphere_radius = 0.22
		feu.direction = Vector3.UP
		feu.spread = 14.0
		feu.initial_velocity_min = c[3] * 0.7
		feu.initial_velocity_max = c[3]
		feu.gravity = Vector3(0, 1.2, 0)
		feu.damping_min = 0.5
		feu.damping_max = 1.0
		feu.angle_min = -180.0
		feu.angle_max = 180.0
		var retrecit := Curve.new()
		retrecit.add_point(Vector2(0.0, 0.7))
		retrecit.add_point(Vector2(0.25, 1.0))
		retrecit.add_point(Vector2(1.0, 0.1))
		feu.scale_amount_curve = retrecit
		_support_flammes.add_child(feu)
		_flammes.append(feu)
	# La fumée : sombre, légère, qui monte lentement en s'élargissant.
	var fumee := _particules(14, 2.8, 0.7, tache, [Color(0.1, 0.09, 0.1, 0.0), Color(0.12, 0.11, 0.12, 0.28), Color(0.1, 0.1, 0.12, 0.0)], false)
	fumee.position.y = 0.9
	fumee.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fumee.emission_sphere_radius = 0.15
	fumee.direction = Vector3.UP
	fumee.spread = 10.0
	fumee.initial_velocity_min = 0.4
	fumee.initial_velocity_max = 0.6
	fumee.gravity = Vector3(0, 0.2, 0)
	var grandit := Curve.new()
	grandit.add_point(Vector2(0.0, 0.5))
	grandit.add_point(Vector2(1.0, 1.6))
	fumee.scale_amount_curve = grandit
	_support_flammes.add_child(fumee)
	_flammes.append(fumee)


## Des particules en panneaux toujours face à la caméra, avec un dégradé de couleurs.
## « lumineuses » : elles s'ajoutent à la lumière (le feu) au lieu de la cacher (la fumée).
func _particules(nombre: int, vie: float, taille: float, tache: Texture2D, couleurs: Array, lumineuses: bool) -> CPUParticles3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if lumineuses else BaseMaterial3D.BLEND_MODE_MIX
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tache
	mat.disable_receive_shadows = true
	var panneau := QuadMesh.new()
	panneau.size = Vector2(taille, taille)
	panneau.material = mat
	var p := CPUParticles3D.new()
	p.mesh = panneau
	p.amount = nombre
	p.lifetime = vie
	p.randomness = 0.4
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var degrade := Gradient.new()
	var positions := PackedFloat32Array()
	for i in couleurs.size():
		positions.append(float(i) / (couleurs.size() - 1))
	degrade.offsets = positions
	degrade.colors = PackedColorArray(couleurs)
	p.color_ramp = degrade
	return p


## Une tache ronde et douce (blanche au centre, transparente au bord).
func _tache_douce() -> Texture2D:
	var degrade := Gradient.new()
	degrade.set_color(0, Color(1, 1, 1, 1))
	degrade.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = degrade
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 64
	texture.height = 64
	return texture


	# Le lit de braises sous les bûches (shaders/braises.gdshader).
	var lit := MeshInstance3D.new()
	var disque := CylinderMesh.new()
	disque.top_radius = 0.55
	disque.bottom_radius = 0.55
	disque.height = 0.02
	disque.radial_segments = 20
	lit.mesh = disque
	var mat_lit := ShaderMaterial.new()
	mat_lit.shader = load("res://shaders/braises.gdshader")
	lit.material_override = mat_lit
	lit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lit.position.y = 0.03
	add_child(lit)


## Des braises qui montent jusqu'à 3,5 m en tourbillonnant, puis renaissent en bas.
func _creer_braises() -> void:
	var forme := BoxMesh.new()
	forme.size = Vector3(0.06, 0.06, 0.06)
	forme.material = _materiau_brillant(Color("f0ad55"))
	_braises = MultiMesh.new()
	_braises.transform_format = MultiMesh.TRANSFORM_3D
	_braises.mesh = forme
	_braises.instance_count = nombre_braises
	var rendu := MultiMeshInstance3D.new()
	rendu.multimesh = _braises
	rendu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rendu)
	for i in nombre_braises:
		_vie_braises.append(randf())


func _animer_braises(delta: float) -> void:
	for i in nombre_braises:
		_vie_braises[i] += delta * (0.36 + (i % 5) * 0.06)
		if _vie_braises[i] > 1.0:
			_vie_braises[i] -= 1.0
		var v := _vie_braises[i]
		var a := i * 2.4
		# Plus la braise monte, plus le vent l'emporte loin.
		var vent := Vent.souffle(_temps - v * 0.8, global_position) * (v * v * 2.2)
		var pos := Vector3(
			cos(a) * 0.25 + sin(_temps * 2.0 + i) * 0.2 * v + vent.x,
			0.4 + v * 3.2,
			sin(a) * 0.25 + cos(_temps * 1.7 + i) * 0.2 * v + vent.z)
		# Les braises rapetissent en montant, comme si elles s'éteignaient.
		var taille := 1.0 - v * 0.7
		_braises.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * taille), pos))


## Un obstacle invisible pour qu'on ne marche pas dans le feu.
func _creer_obstacle() -> void:
	var cylindre := CylinderShape3D.new()
	cylindre.radius = 0.95
	cylindre.height = 1.0
	var zone := CollisionShape3D.new()
	zone.shape = cylindre
	zone.position.y = 0.5
	var corps := StaticBody3D.new()
	corps.add_child(zone)
	add_child(corps)


func _materiau(couleur: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mat.roughness = 1.0
	return mat


## Couleur pleine, non touchée par les ombres : les flammes et les braises « brillent ».
func _materiau_brillant(couleur: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = couleur
	return mat
