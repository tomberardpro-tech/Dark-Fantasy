extends Node3D
## Forêt autour de la clairière, avec les modèles Quaternius (Stylized Nature MegaKit) :
## pins, arbres morts, rochers, et des herbes et champignons dans la clairière.
## Placés au hasard, mais toujours au même endroit grâce à une « graine » fixe.
## Chaque modèle est assombri et teinté vers la palette du jeu (voir CONTEXTE.md).

## Rayon de la clairière (zone sans arbres autour du feu).
@export var rayon_clairiere := 8.0
## Jusqu'où s'étend la forêt.
@export var rayon_foret := 38.0
@export var nombre_pins := 650
@export var nombre_arbres_morts := 80
@export var nombre_rochers := 14
@export var nombre_herbes := 90
## Le long du chemin vers Bruneval.
@export var nombre_pins_chemin := 1100
@export var nombre_arbres_morts_chemin := 120
@export var nombre_rochers_chemin := 40
@export var nombre_herbes_chemin := 160
## Largeur de forêt de chaque côté du chemin (en mètres).
@export var largeur_foret_chemin := 28.0
## Au-delà de cette distance de la caméra, les arbres ne sont plus dessinés (plus fluide).
@export var distance_affichage := 70.0
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
	# La forêt autour de la clairière.
	for i in nombre_pins:
		var pos := _position_libre(func(): return _position_au_hasard(rayon_clairiere + 1.0, rayon_foret))
		_arbre(PINS, pos, _rng.randf_range(0.5, 0.75), SOUPLESSE_PIN)
	for i in nombre_arbres_morts:
		var pos := _position_libre(func(): return _position_au_hasard(rayon_clairiere, rayon_foret))
		_arbre(ARBRES_MORTS, pos, _rng.randf_range(0.32, 0.42), SOUPLESSE_ARBRE_MORT)
	# La forêt de chaque côté du chemin, jusqu'à Bruneval.
	for i in nombre_pins_chemin:
		_arbre(PINS, _position_libre(_position_le_long_du_chemin), _rng.randf_range(0.5, 0.8), SOUPLESSE_PIN)
	for i in nombre_arbres_morts_chemin:
		_arbre(ARBRES_MORTS, _position_libre(_position_le_long_du_chemin), _rng.randf_range(0.32, 0.45), SOUPLESSE_ARBRE_MORT)
	# Le vieil arbre mort au bord de la clairière.
	_arbre(["DeadTree_5"], Vector3(6.0, 0.0, -4.0), 0.5, SOUPLESSE_ARBRE_MORT)
	for i in nombre_rochers:
		var pos := _position_libre(func(): return _position_au_hasard(5.0, 20.0))
		_rocher(pos, _rng.randf_range(0.3, 0.6))
	for i in nombre_rochers_chemin:
		var pos := _position_libre(func(): return _position_pres_du_chemin(3.0, 9.0))
		_rocher(pos, _rng.randf_range(0.25, 0.55))
	# Herbes : surtout au bord de la clairière et du chemin, jamais près du feu.
	for i in nombre_herbes:
		_placer(HERBES, _position_libre(func(): return _position_au_hasard(3.5, 14.0)), _rng.randf_range(0.5, 0.9), SOUPLESSE_HERBE)
	for i in nombre_herbes_chemin:
		_placer(HERBES, _position_libre(func(): return _position_pres_du_chemin(2.2, 7.0)), _rng.randf_range(0.4, 0.8), SOUPLESSE_HERBE)
	for i in 12:
		_placer(["Mushroom_Common"], _position_libre(func(): return _position_pres_du_chemin(3.0, 10.0)), _rng.randf_range(0.6, 1.0))


## Le vent penche doucement les arbres et les herbes, avec un léger balancement.
func _process(delta: float) -> void:
	_temps += delta
	var axe := Vector3.UP.cross(Vent.DIRECTION).normalized()
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	var centre := joueur.global_position if joueur else Vector3.ZERO
	for element in _au_vent:
		var objet: Node3D = element[0]
		# Inutile d'animer ce qui est loin et hors de l'écran.
		if objet.position.distance_squared_to(centre) > 2500.0:
			continue
		var force := Vent.force(_temps, objet.position)
		var balancement := sin(_temps * 2.3 + element[4]) * 0.3
		var angle: float = element[3] * force * (1.0 + balancement)
		objet.basis = Basis(axe, angle) * Basis(Vector3.UP, element[1]).scaled(Vector3.ONE * element[2])


## Cherche un emplacement libre (pas sur le chemin, dans le ruisseau, sur un lieu
## ou dans le hameau), en tirant des points avec « tirage » jusqu'à en trouver un.
func _position_libre(tirage: Callable) -> Vector3:
	var pos: Vector3 = tirage.call()
	for essai in 30:
		if _est_libre(pos):
			return pos
		pos = tirage.call()
	return pos


func _est_libre(pos: Vector3) -> bool:
	if Chemin.distance_au_chemin(pos) < 3.2 or Chemin.distance_au_ruisseau(pos) < 2.2:
		return false
	if pos.distance_to(Chemin.RUINE) < 6.5 or pos.distance_to(Chemin.AUTEL) < 3.5:
		return false
	if pos.distance_to(Chemin.CHARRETTE) < 4.0 or pos.distance_to(Chemin.PONT) < 3.5:
		return false
	return pos.distance_to(Chemin.VILLAGE) > 24.0


## Un point au hasard dans la bande de forêt qui longe le chemin.
func _position_le_long_du_chemin() -> Vector3:
	return _position_pres_du_chemin(3.5, largeur_foret_chemin)


## Un point au hasard à une distance du chemin comprise entre « pres » et « loin ».
func _position_pres_du_chemin(pres: float, loin: float) -> Vector3:
	var courbe: Curve3D = Chemin.courbe_chemin
	var longueur := courbe.get_baked_length()
	var d := _rng.randf_range(0.0, longueur)
	var p := courbe.sample_baked(d)
	var tangente := (courbe.sample_baked(min(d + 1.0, longueur)) - courbe.sample_baked(max(d - 1.0, 0.0))).normalized()
	var cote := Vector3(-tangente.z, 0.0, tangente.x) * (1.0 if _rng.randf() < 0.5 else -1.0)
	return p + cote * _rng.randf_range(pres, loin)


## Un arbre, solide (on ne passe pas à travers son tronc).
func _arbre(noms: Array, pos: Vector3, taille: float, souplesse: float) -> void:
	_placer(noms, pos, taille, souplesse)
	_ajouter_obstacle(pos, 0.35)


func _rocher(pos: Vector3, taille: float) -> void:
	_placer(ROCHERS, pos, taille)
	_ajouter_obstacle(pos, 1.3 * taille)


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
	for maillage in objet.find_children("*", "MeshInstance3D", true, false):
		maillage.visibility_range_end = distance_affichage
		maillage.visibility_range_end_margin = 5.0
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
