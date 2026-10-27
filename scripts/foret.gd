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
@export var nombre_arbres_tordus := 40
@export var nombre_arbres_tordus_chemin := 90
## Largeur de forêt de chaque côté du chemin (en mètres).
@export var largeur_foret_chemin := 28.0
## Au-delà de cette distance de la caméra, les arbres ne sont plus dessinés (plus fluide).
@export var distance_affichage := 70.0
## Combien le vent fait bouger les arbres (1 = très peu, 2,5 = bien visible).
@export var force_vent_arbres := 2.5
## Change ce nombre pour obtenir une autre disposition des arbres.
@export var graine := 2026

const DOSSIER := "res://assets/nature/"
## Le fichier où est figée la place de chaque arbre, rocher et herbe.
const FICHIER_DISPOSITION := "res://donnees/foret.json"
const PINS := ["Pine_1", "Pine_2", "Pine_3", "Pine_4", "Pine_5"]
const ARBRES_MORTS := ["DeadTree_1", "DeadTree_2", "DeadTree_3", "DeadTree_4", "DeadTree_5"]
const ROCHERS := ["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"]
const HERBES := ["Grass_Wispy_Short", "Grass_Wispy_Tall", "Grass_Common_Short"]
const ARBRES_TORDUS := ["TwistedTree_1", "TwistedTree_2", "TwistedTree_3", "TwistedTree_4", "TwistedTree_5"]

## Teinte appliquée à chaque famille de matériaux pour coller à la palette sombre.
const TEINTES := {
	"Leaves": Color(0.42, 0.52, 0.52),
	"Grass": Color(0.42, 0.5, 0.52),
	"Bark": Color(0.55, 0.52, 0.55),
	"Rocks": Color(0.55, 0.58, 0.68),
	"PathRocks": Color(0.5, 0.52, 0.6),
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
## Les places déjà prises, rangées par cases de 4 m (pour éviter les chevauchements).
var _occupe := {}
## Tout ce qui est posé (modèle, place, taille…), pour figer la disposition dans un fichier.
var _disposition: Array = []
var _temps := 0.0


func _ready() -> void:
	# La disposition est figée : on recharge toujours la même, pour que rien ne bouge.
	# Pour changer un élément, on modifie ce fichier (et seulement ce qui est demandé).
	if FileAccess.file_exists(FICHIER_DISPOSITION):
		_charger_disposition()
	else:
		_generer()
		_sauver_disposition()


## Recharge chaque arbre, rocher et herbe exactement là où il était.
func _charger_disposition() -> void:
	var liste: Variant = JSON.parse_string(FileAccess.get_file_as_string(FICHIER_DISPOSITION))
	if not liste is Array:
		push_error("Disposition de la forêt illisible : " + FICHIER_DISPOSITION)
		return
	for e in liste:
		var pos := Vector3(e["x"], 0.0, e["z"])
		if e.has("obstacle"):
			_ajouter_obstacle(pos, e["obstacle"])
		else:
			_poser(e["modele"], pos, e["rotation"], e["taille"], e["souplesse"], e["decalage"])


func _sauver_disposition() -> void:
	var fichier := FileAccess.open(FICHIER_DISPOSITION, FileAccess.WRITE)
	if fichier:
		fichier.store_string(JSON.stringify(_disposition, "\t"))


## Première création de la forêt, au hasard (utilisée seulement s'il n'y a pas de fichier).
func _generer() -> void:
	_rng.seed = graine
	var autour_clairiere := func(): return _position_au_hasard(rayon_clairiere + 1.0, rayon_foret)
	var bord_clairiere := func(): return _position_au_hasard(3.5, 14.0)
	# Le vieil arbre mort au bord de la clairière, placé en premier pour garder sa place.
	_arbre(["DeadTree_5"], Vector3(6.0, 0.0, -4.0), 0.5, SOUPLESSE_ARBRE_MORT, 1.2)
	# Les rochers d'abord (ils sont gros), puis les arbres entre eux.
	for i in nombre_rochers:
		_rocher(_position_au_hasard(5.0, 20.0), _rng.randf_range(0.3, 0.6))
	for i in nombre_rochers_chemin:
		_rocher(_position_pres_du_chemin(3.0, 9.0), _rng.randf_range(0.25, 0.55))
	# La forêt autour de la clairière, puis de chaque côté du chemin jusqu'à Bruneval.
	for i in nombre_pins:
		_arbre(PINS, autour_clairiere.call(), _rng.randf_range(0.5, 0.75), SOUPLESSE_PIN, 0.9)
	for i in nombre_arbres_morts:
		_arbre(ARBRES_MORTS, autour_clairiere.call(), _rng.randf_range(0.32, 0.42), SOUPLESSE_ARBRE_MORT, 0.9)
	for i in nombre_arbres_tordus:
		_arbre(ARBRES_TORDUS, autour_clairiere.call(), _rng.randf_range(0.35, 0.5), SOUPLESSE_PIN, 1.0)
	for i in nombre_pins_chemin:
		_arbre(PINS, _position_le_long_du_chemin(), _rng.randf_range(0.5, 0.8), SOUPLESSE_PIN, 0.9)
	for i in nombre_arbres_morts_chemin:
		_arbre(ARBRES_MORTS, _position_le_long_du_chemin(), _rng.randf_range(0.32, 0.45), SOUPLESSE_ARBRE_MORT, 0.9)
	for i in nombre_arbres_tordus_chemin:
		_arbre(ARBRES_TORDUS, _position_le_long_du_chemin(), _rng.randf_range(0.35, 0.5), SOUPLESSE_PIN, 1.0)
	# Herbes et champignons : au bord de la clairière et du chemin, jamais près du feu.
	for i in nombre_herbes:
		_decor(HERBES, bord_clairiere.call(), _rng.randf_range(0.5, 0.9), SOUPLESSE_HERBE, 0.3)
	for i in nombre_herbes_chemin:
		_decor(HERBES, _position_pres_du_chemin(2.2, 7.0), _rng.randf_range(0.4, 0.8), SOUPLESSE_HERBE, 0.3)
	for i in 14:
		_decor(["Mushroom_Common"], _position_pres_du_chemin(3.0, 10.0), _rng.randf_range(0.6, 1.0), 0.0, 0.3)


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
		# Les arbres (moins souples que les herbes) bougent davantage, à la demande de Tom.
		if element[3] < SOUPLESSE_HERBE:
			balancement = sin(_temps * 1.6 + element[4]) * 0.5
			angle = element[3] * force * force_vent_arbres * (1.0 + balancement)
		objet.basis = Basis(axe, angle) * Basis(Vector3.UP, element[1]).scaled(Vector3.ONE * element[2])


## Vrai si l'endroit est libre : pas sur le chemin, dans le ruisseau, sur un lieu,
## dans le hameau, ni trop près d'un autre objet déjà posé.
## « sur_le_bord » : autorise un objet plat tout au bord du sentier (pierres plates).
func _est_libre(pos: Vector3, rayon: float, sur_le_bord := false) -> bool:
	var marge_chemin := 0.9 if sur_le_bord else 2.2 + rayon
	if Chemin.distance_au_chemin(pos) < marge_chemin or Chemin.distance_au_ruisseau(pos) < 2.4 + rayon:
		return false
	if pos.distance_to(Chemin.RUINE) < 6.5 or pos.distance_to(Chemin.AUTEL) < 3.5:
		return false
	if pos.distance_to(Chemin.CHARRETTE) < 4.5 or pos.distance_to(Chemin.PONT) < 5.0:
		return false
	if Vector2(pos.x, pos.z).length() < 3.2:
		return false
	if pos.distance_to(Chemin.VILLAGE) < 24.0:
		return false
	# Pas de chevauchement avec ce qui est déjà posé (rangé par cases de 4 m).
	var case := Vector2i(floori(pos.x / 4.0), floori(pos.z / 4.0))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for autre in _occupe.get(case + Vector2i(dx, dz), []):
				if Vector2(pos.x - autre.x, pos.z - autre.z).length() < rayon + autre.y:
					return false
	return true


func _reserver(pos: Vector3, rayon: float) -> void:
	var case := Vector2i(floori(pos.x / 4.0), floori(pos.z / 4.0))
	if not _occupe.has(case):
		_occupe[case] = []
	# On range x, rayon, z dans un Vector3 (x, y = rayon, z).
	_occupe[case].append(Vector3(pos.x, rayon, pos.z))


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


## Un arbre, solide (on ne passe pas à travers son tronc). Rien n'est posé si la place
## est déjà prise : la forêt reste propre, sans arbres qui se rentrent dedans.
func _arbre(noms: Array, pos: Vector3, taille: float, souplesse: float, rayon: float) -> void:
	if not _est_libre(pos, rayon):
		return
	_reserver(pos, rayon)
	_placer(noms, pos, taille, souplesse)
	_ajouter_obstacle(pos, 0.35)


func _rocher(pos: Vector3, taille: float) -> void:
	var rayon := 1.5 * taille
	if not _est_libre(pos, rayon):
		return
	_reserver(pos, rayon)
	_placer(ROCHERS, pos, taille)
	_ajouter_obstacle(pos, 1.3 * taille)


## Un petit élément de décor (herbe, buisson, plante, pierre) sans obstacle.
func _decor(noms: Array, pos: Vector3, taille: float, souplesse: float, rayon: float, sur_le_bord := false) -> void:
	if not _est_libre(pos, rayon, sur_le_bord):
		return
	_reserver(pos, rayon)
	_placer(noms, pos, taille, souplesse)


## Un point au hasard dans l'anneau entre rayon_min et rayon_max (répartition régulière).
func _position_au_hasard(rayon_min: float, rayon_max: float) -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var r := sqrt(_rng.randf_range(rayon_min * rayon_min, rayon_max * rayon_max))
	return Vector3(cos(angle) * r, 0.0, sin(angle) * r)


## Pose un modèle choisi au hasard dans la liste, tourné au hasard.
## « souplesse » : combien il plie sous le vent (0 = immobile, comme un rocher).
func _placer(noms: Array, pos: Vector3, taille: float, souplesse := 0.0) -> void:
	var nom: String = noms[_rng.randi_range(0, noms.size() - 1)]
	var rotation_y := _rng.randf_range(0.0, TAU)
	# (Même ordre de tirages qu'avant, pour retrouver exactement la même forêt.)
	var decalage := _rng.randf_range(0.0, TAU) if souplesse > 0.0 else 0.0
	_poser(nom, pos, rotation_y, taille, souplesse, decalage)


## Pose un modèle précis, à un endroit précis, et le note dans la disposition.
func _poser(nom: String, pos: Vector3, rotation_y: float, taille: float, souplesse: float, decalage: float) -> void:
	var objet := _modele(nom).instantiate() as Node3D
	objet.position = pos
	objet.scale = Vector3.ONE * taille
	objet.rotation.y = rotation_y
	add_child(objet)
	_teinter(objet)
	for maillage in objet.find_children("*", "MeshInstance3D", true, false):
		maillage.visibility_range_end = distance_affichage
		maillage.visibility_range_end_margin = 5.0
	if souplesse > 0.0:
		_au_vent.append([objet, rotation_y, taille, souplesse, decalage])
	_disposition.append({"modele": nom, "x": snappedf(pos.x, 0.001), "z": snappedf(pos.z, 0.001),
		"rotation": snappedf(rotation_y, 0.0001), "taille": snappedf(taille, 0.0001),
		"souplesse": souplesse, "decalage": snappedf(decalage, 0.0001)})


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
	_disposition.append({"obstacle": rayon, "x": snappedf(pos.x, 0.001), "z": snappedf(pos.z, 0.001)})
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
