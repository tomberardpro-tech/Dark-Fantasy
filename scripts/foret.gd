extends Node3D
## Forêt autour de la clairière, avec les modèles Quaternius (Stylized Nature MegaKit) :
## pins, arbres morts, rochers, et des herbes et champignons dans la clairière.
## Placés au hasard, mais toujours au même endroit grâce à une « graine » fixe.
## Chaque modèle est assombri et teinté vers la palette du jeu (voir CONTEXTE.md).

## Rayon de la clairière (zone sans arbres autour du feu).
@export var rayon_clairiere := 8.0
## Jusqu'où s'étend la forêt.
@export var rayon_foret := 38.0
@export var nombre_pins := 380
@export var nombre_arbres_morts := 50
@export var nombre_rochers := 14
@export var nombre_herbes := 90
## Change ce nombre pour obtenir une autre disposition des arbres.
@export var graine := 2026

const DOSSIER := "res://assets/nature/"
const PINS := ["Pine_1", "Pine_2", "Pine_3", "Pine_4", "Pine_5"]
const ARBRES_MORTS := ["DeadTree_1", "DeadTree_2", "DeadTree_3", "DeadTree_4", "DeadTree_5"]
const ROCHERS := ["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"]
const HERBES := ["Grass_Wispy_Short", "Grass_Wispy_Tall", "Grass_Common_Short"]

## Teinte appliquée à chaque famille de matériaux pour coller à la palette sombre.
const TEINTES := {
	"Leaves": Color(0.42, 0.52, 0.52),
	"Grass": Color(0.42, 0.5, 0.52),
	"Bark": Color(0.55, 0.52, 0.55),
	"Rocks": Color(0.55, 0.58, 0.68),
	"Mushrooms": Color(0.55, 0.5, 0.55),
}

## Combien chaque famille plie sous le vent (angle maximal, en radians).
const SOUPLESSE_PIN := 0.03
const SOUPLESSE_ARBRE_MORT := 0.015
const SOUPLESSE_HERBE := 0.14

var _rng := RandomNumberGenerator.new()
var _modeles := {}
var _materiaux_teintes := {}
## Tout ce qui se balance au vent : [objet, rotation de départ, taille, souplesse, décalage].
var _au_vent: Array = []
var _temps := 0.0


func _ready() -> void:
	_rng.seed = graine
	for i in nombre_pins:
		var pos := _position_au_hasard(rayon_clairiere + 1.0, rayon_foret)
		_placer(PINS, pos, _rng.randf_range(0.5, 0.75), SOUPLESSE_PIN)
		_ajouter_obstacle(pos, 0.35)
	for i in nombre_arbres_morts:
		var pos := _position_au_hasard(rayon_clairiere, rayon_foret)
		_placer(ARBRES_MORTS, pos, _rng.randf_range(0.32, 0.42), SOUPLESSE_ARBRE_MORT)
		_ajouter_obstacle(pos, 0.35)
	# Le vieil arbre mort au bord de la clairière.
	_placer(["DeadTree_5"], Vector3(6.0, 0.0, -4.0), 0.5, SOUPLESSE_ARBRE_MORT)
	_ajouter_obstacle(Vector3(6.0, 0.0, -4.0), 0.5)
	for i in nombre_rochers:
		var pos := _position_au_hasard(5.0, 20.0)
		var taille := _rng.randf_range(0.3, 0.6)
		_placer(ROCHERS, pos, taille)
		_ajouter_obstacle(pos, 1.3 * taille)
	# Herbes : surtout au bord de la clairière, jamais près du feu.
	for i in nombre_herbes:
		_placer(HERBES, _position_au_hasard(3.5, 14.0), _rng.randf_range(0.5, 0.9), SOUPLESSE_HERBE)
	for i in 6:
		_placer(["Mushroom_Common"], _position_au_hasard(5.0, 10.0), _rng.randf_range(0.6, 1.0))


## Le vent penche doucement les arbres et les herbes, avec un léger balancement.
func _process(delta: float) -> void:
	_temps += delta
	var axe := Vector3.UP.cross(Vent.DIRECTION).normalized()
	for element in _au_vent:
		var objet: Node3D = element[0]
		var force := Vent.force(_temps, objet.position)
		var balancement := sin(_temps * 2.3 + element[4]) * 0.3
		var angle: float = element[3] * force * (1.0 + balancement)
		objet.basis = Basis(axe, angle) * Basis(Vector3.UP, element[1]).scaled(Vector3.ONE * element[2])


## Un point au hasard dans l'anneau entre rayon_min et rayon_max (répartition régulière).
func _position_au_hasard(rayon_min: float, rayon_max: float) -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var r := sqrt(_rng.randf_range(rayon_min * rayon_min, rayon_max * rayon_max))
	return Vector3(cos(angle) * r, 0.0, sin(angle) * r)


## Pose un modèle choisi au hasard dans la liste, tourné au hasard.
## « souplesse » : combien il plie sous le vent (0 = immobile, comme un rocher).
func _placer(noms: Array, pos: Vector3, taille: float, souplesse := 0.0) -> void:
	var nom: String = noms[_rng.randi_range(0, noms.size() - 1)]
	var objet := _modele(nom).instantiate() as Node3D
	var rotation_y := _rng.randf_range(0.0, TAU)
	objet.position = pos
	objet.scale = Vector3.ONE * taille
	objet.rotation.y = rotation_y
	add_child(objet)
	_teinter(objet)
	if souplesse > 0.0:
		_au_vent.append([objet, rotation_y, taille, souplesse, _rng.randf_range(0.0, TAU)])


func _modele(nom: String) -> PackedScene:
	if not _modeles.has(nom):
		_modeles[nom] = load(DOSSIER + nom + ".gltf")
	return _modeles[nom]


## Remplace les matériaux du modèle par une version assombrie et teintée.
func _teinter(objet: Node) -> void:
	for maillage in objet.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = maillage.mesh
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i) as StandardMaterial3D
			if mat:
				maillage.set_surface_override_material(i, _materiau_teinte(mat))


func _materiau_teinte(original: StandardMaterial3D) -> StandardMaterial3D:
	if _materiaux_teintes.has(original):
		return _materiaux_teintes[original]
	var copie := original.duplicate() as StandardMaterial3D
	var teinte := Color(0.6, 0.6, 0.65)
	for famille in TEINTES:
		if original.resource_name.begins_with(famille):
			teinte = TEINTES[famille]
	copie.albedo_color = original.albedo_color * teinte
	copie.roughness = 1.0
	copie.metallic_specular = 0.2
	_materiaux_teintes[original] = copie
	return copie


## Un obstacle invisible autour d'un tronc ou d'un rocher, pour qu'on ne passe pas à travers.
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
