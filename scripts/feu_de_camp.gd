extends Node3D
## Feu de camp en formes simples : pierres, bûches, flammes qui vacillent, braises
## et une lumière orange qui tremble.

## Puissance de la lumière du feu.
@export var puissance := 3.0
## Distance éclairée par le feu (en mètres).
@export var portee := 10.0

var _flammes: Array[MeshInstance3D] = []
var _lumiere: OmniLight3D
var _temps := 0.0


func _ready() -> void:
	_creer_pierres()
	_creer_buches()
	_creer_flammes()
	_creer_braises()
	_lumiere = OmniLight3D.new()
	_lumiere.light_color = Color("e0823a")
	_lumiere.light_energy = puissance
	_lumiere.omni_range = portee
	_lumiere.shadow_enabled = true
	_lumiere.position.y = 1.0
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


func _creer_pierres() -> void:
	var mat := _materiau(Color("5d6372"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		var a := TAU * i / 9.0
		var forme := BoxMesh.new()
		forme.size = Vector3(0.32, 0.22, 0.26)
		var pierre := MeshInstance3D.new()
		pierre.mesh = forme
		pierre.material_override = mat
		pierre.position = Vector3(cos(a) * 0.8, 0.1, sin(a) * 0.8)
		pierre.rotation = Vector3(0.0, -a + rng.randf_range(-0.3, 0.3), rng.randf_range(-0.2, 0.2))
		add_child(pierre)


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
	for f in [[Color("d07a35"), 0.42, 1.1], [Color("f0ad55"), 0.3, 0.85], [Color("ffe0a0"), 0.15, 0.6]]:
		var forme := CylinderMesh.new()
		forme.top_radius = 0.0
		forme.bottom_radius = f[1]
		forme.height = f[2]
		forme.radial_segments = 6
		var flamme := MeshInstance3D.new()
		flamme.mesh = forme
		flamme.material_override = _materiau_lumineux(f[0], 3.0)
		flamme.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flamme.set_meta("hauteur", f[2])
		flamme.position.y = 0.2 + f[2] / 2.0
		add_child(flamme)
		_flammes.append(flamme)


func _creer_braises() -> void:
	var forme := BoxMesh.new()
	forme.size = Vector3(0.05, 0.05, 0.05)
	forme.material = _materiau_lumineux(Color("f0ad55"), 4.0)
	var braises := CPUParticles3D.new()
	braises.mesh = forme
	braises.amount = 30
	braises.lifetime = 1.6
	braises.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	braises.emission_sphere_radius = 0.3
	braises.direction = Vector3.UP
	braises.spread = 20.0
	braises.gravity = Vector3(0.0, 0.5, 0.0)
	braises.initial_velocity_min = 0.6
	braises.initial_velocity_max = 1.2
	braises.scale_amount_min = 0.5
	braises.scale_amount_max = 1.2
	braises.position.y = 0.4
	add_child(braises)


func _materiau(couleur: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mat.roughness = 1.0
	return mat


func _materiau_lumineux(couleur: Color, intensite: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	mat.emission_enabled = true
	mat.emission = couleur
	mat.emission_energy_multiplier = intensite
	return mat
