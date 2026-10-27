extends Node3D
## Forêt autour de la clairière, en formes simples : des pins (cônes empilés), des arbres
## morts tordus et quelques rochers. Placés au hasard, mais toujours au même endroit
## grâce à une « graine » fixe.

## Rayon de la clairière (zone sans arbres autour du feu).
@export var rayon_clairiere := 8.0
## Jusqu'où s'étend la forêt.
@export var rayon_foret := 38.0
@export var nombre_pins := 260
@export var nombre_arbres_morts := 30
@export var nombre_rochers := 18
## Change ce nombre pour obtenir une autre disposition des arbres.
@export var graine := 2026

var _rng := RandomNumberGenerator.new()
var _mat_aiguilles: Array[StandardMaterial3D] = []
var _mat_tronc_pin: StandardMaterial3D
var _mat_bois_mort: StandardMaterial3D
var _mat_roche: StandardMaterial3D


func _ready() -> void:
	_rng.seed = graine
	for c in ["18211f", "26332f", "2e3d3a"]:
		_mat_aiguilles.append(_materiau(Color(c)))
	_mat_tronc_pin = _materiau(Color("2a221f"))
	_mat_bois_mort = _materiau(Color("3d3530"))
	_mat_roche = _materiau(Color("4b5160"))

	for i in nombre_pins:
		_pin(_position_au_hasard(rayon_clairiere + 1.0, rayon_foret), _rng.randf_range(0.8, 1.5))
	for i in nombre_arbres_morts:
		_arbre_mort(_position_au_hasard(rayon_clairiere, rayon_foret), _rng.randf_range(0.8, 1.2))
	# Le vieil arbre mort au bord de la clairière.
	_arbre_mort(Vector3(6.0, 0.0, -4.0), 1.5)
	for i in nombre_rochers:
		_rocher(_position_au_hasard(5.0, 20.0), _rng.randf_range(0.4, 1.1))


## Un point au hasard dans l'anneau entre rayon_min et rayon_max (répartition régulière).
func _position_au_hasard(rayon_min: float, rayon_max: float) -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var r := sqrt(_rng.randf_range(rayon_min * rayon_min, rayon_max * rayon_max))
	return Vector3(cos(angle) * r, 0.0, sin(angle) * r)


func _pin(pos: Vector3, taille: float) -> void:
	var pin := Node3D.new()
	pin.position = pos
	pin.scale = Vector3.ONE * taille
	pin.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(pin)
	_ajouter_obstacle(pos, 0.3 * taille)
	_ajouter_cylindre(pin, 0.15, 0.25, 1.4, Vector3(0, 0.7, 0), _mat_tronc_pin)
	var mat := _mat_aiguilles[_rng.randi_range(0, _mat_aiguilles.size() - 1)]
	# [largeur, hauteur, altitude] de chaque étage d'aiguilles, du bas vers le haut.
	for etage in [[1.5, 2.3, 1.9], [1.15, 2.0, 3.0], [0.75, 1.7, 4.0]]:
		_ajouter_cylindre(pin, 0.0, etage[0], etage[1], Vector3(0, etage[2], 0), mat)


func _arbre_mort(pos: Vector3, taille: float) -> void:
	var arbre := Node3D.new()
	arbre.position = pos
	arbre.scale = Vector3.ONE * taille
	arbre.rotation = Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.08, 0.08))
	add_child(arbre)
	_ajouter_obstacle(pos, 0.3 * taille)
	_ajouter_cylindre(arbre, 0.1, 0.28, 4.0, Vector3(0, 2.0, 0), _mat_bois_mort)
	# Quelques branches nues et tordues.
	for i in _rng.randi_range(2, 4):
		var pivot := Node3D.new()
		pivot.position.y = _rng.randf_range(1.8, 3.5)
		pivot.rotation = Vector3(0.0, _rng.randf_range(0.0, TAU), _rng.randf_range(0.7, 1.1))
		arbre.add_child(pivot)
		var longueur := _rng.randf_range(1.0, 1.8)
		_ajouter_cylindre(pivot, 0.03, 0.08, longueur, Vector3(0, longueur / 2.0, 0), _mat_bois_mort)


func _rocher(pos: Vector3, taille: float) -> void:
	var forme := BoxMesh.new()
	forme.size = Vector3(1.0, 0.6, 0.8) * taille
	var rocher := MeshInstance3D.new()
	rocher.mesh = forme
	rocher.material_override = _mat_roche
	rocher.position = pos + Vector3(0, 0.2 * taille, 0)
	rocher.rotation = Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.3, 0.3))
	add_child(rocher)
	# Le rocher est solide : on ne peut pas passer à travers.
	var bloc := BoxShape3D.new()
	bloc.size = forme.size
	var zone := CollisionShape3D.new()
	zone.shape = bloc
	var corps := StaticBody3D.new()
	corps.transform = rocher.transform
	corps.add_child(zone)
	add_child(corps)


## Un obstacle invisible autour d'un tronc, pour que le personnage ne traverse pas l'arbre.
func _ajouter_obstacle(pos: Vector3, rayon: float) -> void:
	var cylindre := CylinderShape3D.new()
	cylindre.radius = rayon
	cylindre.height = 3.0
	var zone := CollisionShape3D.new()
	zone.shape = cylindre
	zone.position.y = 1.5
	var corps := StaticBody3D.new()
	corps.position = pos
	corps.add_child(zone)
	add_child(corps)


func _ajouter_cylindre(parent: Node3D, haut: float, bas: float, hauteur: float, pos: Vector3, mat: Material) -> void:
	var forme := CylinderMesh.new()
	forme.top_radius = haut
	forme.bottom_radius = bas
	forme.height = hauteur
	forme.radial_segments = 6
	forme.rings = 1
	var morceau := MeshInstance3D.new()
	morceau.mesh = forme
	morceau.material_override = mat
	morceau.position = pos
	parent.add_child(morceau)


func _materiau(couleur: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mat.roughness = 1.0
	return mat
