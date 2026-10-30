extends Node3D
## L'intérieur de la maison du chef : une pièce à part (loin du monde, dans le noir), comme
## dans Pokémon. Le mur du fond et les deux murs de côté sont montrés ; le mur du devant
## (côté caméra) est ouvert pour qu'on voie dedans. Une cheminée, une grande table, un lit,
## une bibliothèque, des chandeliers. On ressort par le bas de la pièce.
##
## Les positions sont « comme à l'écran » : x vers la droite, z vers le bas de l'écran.

const LARGEUR := 8.0
const PROFONDEUR := 6.0
const FEU := Color("ff7a30")

## Où le héros arrive en entrant, où est la sortie, et où se tient le chef.
var arrivee := Vector3.ZERO
var sortie := Vector3.ZERO
var place_du_chef := Vector3.ZERO

var _rng := RandomNumberGenerator.new()
var _lumieres: Array[OmniLight3D] = []
var _temps := 0.0


func _ready() -> void:
	_rng.seed = 77
	# La pièce est tournée comme l'écran : son +X va vers la droite, son +Z vers le bas.
	basis = Basis(Chemin.DROITE_ECRAN, Vector3.UP, -Chemin.HAUT_ECRAN)
	arrivee = to_global(Vector3(0, 0, 1.4))
	sortie = to_global(Vector3(0, 0, 2.7))
	place_du_chef = to_global(Vector3(0.9, 0, -1.25))
	_sol()
	_murs()
	_cheminee()
	_meubles()
	_seuil()


## La lueur de la cheminée et des bougies vacille.
func _process(delta: float) -> void:
	_temps += delta
	for i in _lumieres.size():
		var base: float = _lumieres[i].get_meta("base")
		_lumieres[i].light_energy = base * (1.0 + sin(_temps * 9.0 + i * 1.7) * 0.08 + sin(_temps * 5.3 + i) * 0.06)


func _sol() -> void:
	for x in [-3.0, -1.0, 1.0, 3.0]:
		for z in [-2.0, 0.0, 2.0]:
			_poser("Floor_WoodDark", Vector3(x, 0.01, z))
	# Tout autour de la pièce, du noir complet (demande de Tom), jusqu'aux bords de l'écran.
	var noir := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2(300.0, 300.0)
	noir.mesh = plan
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.BLACK
	mat.disable_fog = true
	noir.material_override = mat
	noir.position.y = -0.01
	add_child(noir)


## Le mur du fond (deux fenêtres, la cheminée au milieu) et les murs de gauche et de droite.
## Des murs invisibles ferment aussi le devant.
func _murs() -> void:
	var demi_l := LARGEUR / 2.0
	var demi_p := PROFONDEUR / 2.0
	var fond := ["Wall_Plaster_Window_Wide_Flat", "Wall_Plaster_Straight", "Wall_Plaster_Straight", "Wall_Plaster_Window_Wide_Flat"]
	for i in 4:
		_poser(fond[i], Vector3(-3.0 + i * 2.0, 0, -demi_p), PI)
	for cote in [-1.0, 1.0]:
		for i in 3:
			var modele := "Wall_Plaster_WoodGrid" if i == 1 else "Wall_Plaster_Straight"
			_poser(modele, Vector3(cote * demi_l, 0, -2.0 + i * 2.0), cote * PI / 2.0)
		_poser("Corner_Exterior_Wood", Vector3(cote * demi_l, 0, -demi_p))
	# La nuit dehors, derrière les fenêtres : un bleu froid.
	for x in [-3.0, 3.0]:
		var vitre := MeshInstance3D.new()
		var plan := QuadMesh.new()
		plan.size = Vector2(1.3, 1.2)
		vitre.mesh = plan
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.12, 0.16, 0.3)
		vitre.material_override = mat
		vitre.position = Vector3(x, 1.72, -demi_p - 0.2)
		add_child(vitre)
	for mur in [[Vector3(0, 1.5, -demi_p - 0.1), Vector3(LARGEUR, 3.0, 0.4)], [Vector3(0, 1.5, demi_p + 0.2), Vector3(LARGEUR, 3.0, 0.4)],
			[Vector3(-demi_l - 0.1, 1.5, 0), Vector3(0.4, 3.0, PROFONDEUR)], [Vector3(demi_l + 0.1, 1.5, 0), Vector3(0.4, 3.0, PROFONDEUR)]]:
		_obstacle(mur[0], mur[1])


## La cheminée de briques au milieu du mur du fond, avec ses braises.
func _cheminee() -> void:
	var briques := Modeles.materiau_de("Wall_UnevenBrick_Straight")
	for bloc in [[Vector3(0, 0.75, -2.65), Vector3(2.0, 1.5, 0.6)], [Vector3(0, 2.3, -2.75), Vector3(1.4, 1.6, 0.4)]]:
		var forme := MeshInstance3D.new()
		var boite := BoxMesh.new()
		boite.size = bloc[1]
		forme.mesh = boite
		forme.material_override = briques
		forme.position = bloc[0]
		add_child(forme)
	# Le foyer : un trou noir et des braises rougeoyantes.
	var foyer := MeshInstance3D.new()
	var trou := QuadMesh.new()
	trou.size = Vector2(1.2, 0.9)
	foyer.mesh = trou
	var noir := StandardMaterial3D.new()
	noir.albedo_color = Color(0.03, 0.02, 0.02)
	foyer.material_override = noir
	foyer.position = Vector3(0, 0.55, -2.34)
	add_child(foyer)
	var braises := MeshInstance3D.new()
	var tas := BoxMesh.new()
	tas.size = Vector3(0.9, 0.08, 0.35)
	braises.mesh = tas
	var rouge := StandardMaterial3D.new()
	rouge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rouge.albedo_color = Color("ff6a1f")
	braises.material_override = rouge
	braises.position = Vector3(0, 0.16, -2.45)
	add_child(braises)
	_lumiere(Vector3(0, 0.8, -1.9), FEU, 2.2, 7.0)
	_obstacle(Vector3(0, 0.75, -2.65), Vector3(2.0, 1.5, 0.6))


func _meubles() -> void:
	# La grande table du chef, ses chaises, des livres et une bougie.
	_poser("Table_Large", Vector3(0.9, 0, -0.3))
	_obstacle(Vector3(0.9, 0.4, -0.3), Vector3(2.85, 0.8, 1.1))
	_poser("Chair_1", Vector3(0.2, 0, 0.55), PI)
	_poser("Chair_1", Vector3(1.6, 0, 0.55), PI + 0.15)
	_poser("BookGroup_Medium_1", Vector3(1.5, 0.81, -0.45), 0.2)
	_poser("Scroll_1", Vector3(0.4, 0.81, -0.2), 0.8)
	_poser("CandleStick", Vector3(-0.2, 0.81, -0.4))
	_lumiere(Vector3(-0.2, 1.3, -0.4), Color("f2b766"), 0.8, 4.0)
	# Le lit, dans le coin du fond à gauche, et un coffre à son pied.
	_poser("Bed_Twin1", Vector3(-3.0, 0, -1.65))
	_obstacle(Vector3(-3.0, 0.4, -1.65), Vector3(1.9, 0.8, 2.4))
	_poser("Chest_Wood", Vector3(-3.0, 0, 0.2))
	_obstacle(Vector3(-3.0, 0.35, 0.2), Vector3(1.3, 0.7, 0.8))
	# La bibliothèque et un buffet contre le mur de droite.
	_poser("Bookcase_2", Vector3(3.7, 0, -1.4), -PI / 2.0)
	_obstacle(Vector3(3.7, 1.2, -1.4), Vector3(0.5, 2.4, 1.5))
	_poser("Cabinet", Vector3(3.75, 0, 0.9), -PI / 2.0)
	_obstacle(Vector3(3.75, 0.5, 0.9), Vector3(0.4, 1.0, 1.4))
	# Une bannière au mur, et deux grands chandeliers de part et d'autre de la cheminée.
	_poser("Banner_1", Vector3(-1.9, 2.45, -2.75))
	for x in [-1.5, 1.6]:
		_poser("CandleStick_Stand", Vector3(x, 0, -2.3))
		_lumiere(Vector3(x, 1.5, -2.1), Color("f2b766"), 0.7, 3.5)


## Le seuil de la porte, en bas de la pièce : un paillasson et un filet de lumière froide
## qui entre de dehors.
func _seuil() -> void:
	var tapis := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2(1.6, 0.9)
	tapis.mesh = plan
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.18, 0.12)
	tapis.material_override = mat
	tapis.position = Vector3(0, 0.03, 2.6)
	add_child(tapis)
	_lumiere(Vector3(0, 1.5, 3.4), Color(0.5, 0.6, 0.9), 0.6, 4.0)


func _poser(nom: String, ou: Vector3, angle := 0.0) -> void:
	var objet := Modeles.creer(nom)
	objet.position = ou
	objet.rotation.y = angle
	add_child(objet)


func _lumiere(ou: Vector3, couleur: Color, force: float, portee: float) -> void:
	var lumiere := OmniLight3D.new()
	lumiere.light_color = couleur
	lumiere.light_energy = force
	lumiere.omni_range = portee
	lumiere.shadow_enabled = force > 1.0
	lumiere.position = ou
	lumiere.set_meta("base", force)
	add_child(lumiere)
	_lumieres.append(lumiere)


## Un obstacle invisible (centre et taille dans la pièce).
func _obstacle(centre: Vector3, taille: Vector3) -> void:
	var forme := BoxShape3D.new()
	forme.size = taille
	var zone := CollisionShape3D.new()
	zone.shape = forme
	var corps := StaticBody3D.new()
	corps.position = centre
	corps.add_child(zone)
	add_child(corps)
