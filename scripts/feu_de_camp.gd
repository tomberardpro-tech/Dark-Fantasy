extends Node3D
## Feu de camp, animé comme sur la maquette : un cercle de galets, des bûches,
## trois flammes qui vacillent et tournent, des braises qui montent en tourbillonnant,
## et une lumière orange qui tremble.

## Puissance de la lumière du feu.
@export var puissance := 2.6
## Distance éclairée par le feu (en mètres).
@export var portee := 14.0
## Nombre de braises qui s'envolent.
@export var nombre_braises := 40

const GALETS := ["Pebble_Round_1", "Pebble_Round_2", "Pebble_Round_3", "Pebble_Round_4", "Pebble_Round_5"]

var _flammes: Array[MeshInstance3D] = []
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
	_lumiere = OmniLight3D.new()
	_lumiere.light_color = Color("e0823a")
	_lumiere.light_energy = puissance
	_lumiere.omni_range = portee
	_lumiere.omni_attenuation = 1.6
	_lumiere.shadow_enabled = true
	_lumiere.position.y = 1.1
	add_child(_lumiere)


func _process(delta: float) -> void:
	_temps += delta
	# Plusieurs vagues mélangées pour un vacillement qui ne semble pas répétitif.
	var v := 0.85 + sin(_temps * 13.0) * 0.08 + sin(_temps * 7.3) * 0.07 + sin(_temps * 23.0) * 0.04
	_lumiere.light_energy = puissance * v
	for i in _flammes.size():
		var flamme := _flammes[i]
		var k := v + sin(_temps * (9.0 + i * 4.0)) * 0.08
		var hauteur: float = flamme.get_meta("hauteur")
		flamme.scale = Vector3(1.0, k, 1.0)
		flamme.position.y = 0.2 + hauteur * k / 2.0
		flamme.rotation.y = _temps * (0.8 + i)
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
	var mat := _materiau(Color("4a3b31"))
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
	# [couleur, largeur, hauteur] : de la grande flamme orange au cœur jaune pâle.
	for f in [[Color("d07a35"), 0.42, 1.2], [Color("f0ad55"), 0.3, 0.95], [Color("ffe0a0"), 0.16, 0.65]]:
		var forme := CylinderMesh.new()
		forme.top_radius = 0.0
		forme.bottom_radius = f[1]
		forme.height = f[2]
		forme.radial_segments = 6
		var flamme := MeshInstance3D.new()
		flamme.mesh = forme
		flamme.material_override = _materiau_brillant(f[0])
		flamme.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flamme.set_meta("hauteur", f[2])
		flamme.position.y = 0.2 + f[2] / 2.0
		add_child(flamme)
		_flammes.append(flamme)


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
		var pos := Vector3(
			cos(a) * 0.25 + sin(_temps * 2.0 + i) * 0.2 * v,
			0.4 + v * 3.2,
			sin(a) * 0.25 + cos(_temps * 1.7 + i) * 0.2 * v)
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
