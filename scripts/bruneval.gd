extends Node3D
## Le hameau de Bruneval, d'après la maquette choisie par Tom : de petites maisons serrées
## autour d'une place de terre boueuse (feu de camp, banc, puits), toutes tournées vers le
## feu ; la maison du chef (à étage) au fond, la forge en briques à gauche, la médecin à
## droite, deux abris devant, l'étal d'Osric. Pas de palissade : une
## ceinture de sapins entoure la clairière (voir foret.json). Pièces du Medieval Village
## MegaKit et du Fantasy Props MegaKit (Quaternius).
##
## Les positions sont celles de la maquette (x vers la droite de l'écran, y vers le haut),
## converties par Chemin.bruneval().

const TEINTE_PIERRE := Color(0.55, 0.58, 0.68)
const COULEUR_FENETRE := Color("f2b766")
## Les maisons sont un peu plus petites que les pièces du pack (Tom les veut petites).
const ECHELLE_MAISONS := 0.8

var _rng := RandomNumberGenerator.new()
var _feux: Array[OmniLight3D] = []
var _temps := 0.0
## La porte de la maison du chef (dehors) et la direction de la place depuis elle.
var _porte_chef := Vector3.ZERO
var _devant_chef := Vector3.ZERO
## L'intérieur de la maison du chef, loin du monde (voir interieur_chef.gd).
const INTERIEUR_CHEF := Vector3(2000, 0, 2000)
var _interieur: Node3D
## Où se tiennent le forgeron et le médecin, derrière leur étal.
var _poste_forgeron := Vector3.ZERO
var _poste_medecin := Vector3.ZERO
var _enclume_forge := Vector3.ZERO
## Devant la forge et l'étal de la médecin (là où arrivent les sentiers), et la porte de
## chaque maison : [position, direction vers l'extérieur].
var _devant_forge := Vector3.ZERO
var _devant_medecin := Vector3.ZERO
var _portes := {}
## Chaque maison (son nœud), pour poser des objets autour, et l'étal de la médecin.
var _maisons := {}
var _etal_medecin: Node3D
## Le côté de l'étal où se tient la médecin (vers le bas de l'écran).
var _cote_medecin := Vector3.ZERO
## Le poteau de droite de l'entrée du rempart (Bran s'y adosse) et la place d'Osric.
var _poteau_entree := Vector3.ZERO
var _poste_osric := Vector3.ZERO
var _regard_osric := Vector3.ZERO


func _ready() -> void:
	add_to_group("bruneval")
	_rng.seed = 1848
	_creer_place()
	# Comme sur la maquette de Tom : de petites maisons serrées autour de la place, toutes
	# tournées vers le feu, le forgeron et la médecin devant leur stand. Chacune est un peu
	# de travers, et les deux abris ne sont plus en miroir, pour casser la symétrie.
	# [x, y, largeur, longueur de façade, étages, briques, nom,
	# rotation vers la place (0 = face à la caméra, 1 = face au feu), petit écart d'angle]
	_maison(0.0, 10.0, 4, 6, 1, false, "Maison du chef", 1.0, 0.05)
	_maison(-11.0, 2.5, 4, 4, 1, true, "Forge", 1.0, 0.12)
	_maison(11.3, 2.4, 4, 4, 1, false, "Médecin", 1.0, -0.1)
	_maison(-9.9, -8.1, 4, 4, 1, false, "Abri", 1.0, -0.22)
	_maison(9.0, -9.1, 4, 4, 1, false, "Abri de l'est", 1.0, 0.18)
	_creer_forge(-11.0, 2.5)
	_creer_feu()
	_creer_puits(-3.6, 4.6)
	_creer_etal(-6.0, -5.2)
	_creer_etal_medecin(11.3, 2.4)
	_chemin_de_sortie()
	_regler_le_sol()
	_creer_traces_de_pas()
	_creer_flaques()
	_creer_rempart()
	# L'identité de chaque lieu, les lanternes et les signes de vie (étapes 3, 4 et 6).
	_decorer_forge()
	_decorer_medecin()
	_decorer_chef()
	_decorer_abris()
	_creer_lanternes()
	_creer_vie_du_village()
	_creer_interieur_du_chef()
	_creer_survivants()


## Où l'on arrive en entrant chez le chef (utilisé aussi par le raccourci F4).
func arrivee_chez_le_chef() -> Vector3:
	return _interieur.arrivee


## La maison du chef : sa porte (E pour entrer), la pièce à part, et la porte pour ressortir.
func _creer_interieur_du_chef() -> void:
	_interieur = Node3D.new()
	_interieur.name = "Intérieur du chef"
	_interieur.set_script(load("res://scripts/interieur_chef.gd"))
	_interieur.position = INTERIEUR_CHEF
	add_child(_interieur)
	var entree := Node3D.new()
	entree.set_script(load("res://scripts/porte.gd"))
	entree.name = "Porte du chef"
	entree.texte = "E : entrer chez le chef"
	entree.arrivee = _interieur.arrivee
	entree.regard = Chemin.HAUT_ECRAN
	entree.vers_l_interieur = true
	entree.position = _porte_chef + _devant_chef * 0.6
	add_child(entree)
	var sortie := Node3D.new()
	sortie.set_script(load("res://scripts/porte.gd"))
	sortie.name = "Sortie du chef"
	sortie.texte = "E : sortir"
	sortie.arrivee = _porte_chef + _devant_chef * 2.2
	sortie.regard = _devant_chef
	sortie.vers_l_interieur = false
	sortie.portee = 1.2
	sortie.position = _interieur.sortie
	add_child(sortie)


## La lueur de la forge vacille.
func _process(delta: float) -> void:
	_temps += delta
	for i in _feux.size():
		_feux[i].light_energy = 1.9 + sin(_temps * 3.1 + i) * 0.12 + sin(_temps * 1.7) * 0.08


# --- La place -------------------------------------------------------------------

## La place : un ovale de terre boueuse (même matière que le chemin,
## avec ses flaques), autour du feu.
func _creer_place() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/chemin.gdshader")
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tours := 40
	var centre := Chemin.VILLAGE + Vector3(0, 0.025, 0)
	# Pour chaque tranche : un triangle du centre au bord, puis le fondu vers l'extérieur.
	for i in tours:
		var points := []
		for k in [0, 1]:
			var t: float = TAU * (i + k) / tours
			var r := 1.0 + 0.07 * sin(t * 3.0 + 0.5)
			points.append(Chemin.bruneval(9.0 * r * sin(t), 7.0 * r * cos(t)) + Vector3(0, 0.025, 0))
		var a: Vector3 = points[0]
		var b: Vector3 = points[1]
		var a2 := centre + (a - centre) * 1.9
		var b2 := centre + (b - centre) * 1.9
		for v in [[centre, 0.0], [a, 1.0], [b, 1.0], [a, 1.0], [a2, 1.9], [b, 1.0], [b, 1.0], [a2, 1.9], [b2, 1.9]]:
			outil.set_color(Color(0.35, 0, 0, 1))
			outil.set_normal(Vector3.UP)
			outil.set_uv(Vector2(v[1], 0))
			outil.add_vertex(v[0])
	var place := MeshInstance3D.new()
	place.mesh = outil.commit()
	place.material_override = mat
	place.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(place)


func _creer_feu() -> void:
	var feu := Node3D.new()
	feu.set_script(load("res://scripts/feu_de_camp.gd"))
	feu.puissance = 4.5
	feu.portee = 14.0
	feu.position = Chemin.VILLAGE
	add_child(feu)
	# Deux bancs tournés vers le feu : celui du vieux Hugo, et un autre en face, à droite.
	for place in [[Vector2(-2.8, -2.9), 0.1], [Vector2(3.0, -2.6), -0.15]]:
		var banc := Modeles.creer("Bench")
		banc.position = Chemin.bruneval(place[0].x, place[0].y)
		banc.rotation.y = _vers(banc.position, feu.position) + place[1]
		add_child(banc)
		var forme := BoxShape3D.new()
		forme.size = Vector3(2.8, 0.5, 0.55)
		_obstacle(forme, Transform3D(Basis(Vector3.UP, banc.rotation.y), banc.position + Vector3(0, 0.25, 0)))


# --- Les maisons ------------------------------------------------------------------

## Une maison de « largeur » × « profondeur » mètres (multiples de 2), d'un ou deux étages,
## en plâtre ou en briques. Sa façade (avec la porte, sous le pignon) regarde la place.
func _maison(x: float, y: float, largeur: int, profondeur: int, etages: int, briques: bool, nom: String, vers_place := 0.0, ecart := 0.0) -> void:
	var maison := Node3D.new()
	maison.name = nom
	maison.position = Chemin.bruneval(x, y)
	# La façade (le long côté, en +X) regarde la caméra, un peu tournée vers la place
	# selon « vers_place » (0 = droit face à la caméra).
	var vers_camera := -Chemin.HAUT_ECRAN
	var vers_le_feu := (Chemin.VILLAGE - maison.position).normalized()
	var facade := vers_camera.lerp(vers_le_feu, vers_place).normalized()
	maison.rotation.y = atan2(-facade.z, facade.x) + ecart
	maison.scale = Vector3.ONE * ECHELLE_MAISONS
	add_child(maison)
	var prefixe := "Wall_UnevenBrick_" if briques else "Wall_Plaster_"
	var murs_pleins := ["Wall_UnevenBrick_Straight"] if briques else ["Wall_Plaster_Straight", "Wall_Plaster_WoodGrid"]
	var demi_l := largeur / 2.0
	var demi_p := profondeur / 2.0
	var porte := _rng.randi_range(0, profondeur / 2 - 1)
	for etage in etages:
		var h := etage * 3.0
		# Les quatre côtés : [nombre de pans, position du pan, rotation].
		for cote in 4:
			var pans := (largeur if cote % 2 == 0 else profondeur) / 2
			for i in pans:
				var long := -((largeur if cote % 2 == 0 else profondeur) / 2.0) + 1.0 + i * 2.0
				var pos := Vector3.ZERO
				var angle := 0.0
				match cote:
					0: pos = Vector3(long, h, demi_p)
					1: pos = Vector3(demi_l, h, -long); angle = PI / 2.0
					2: pos = Vector3(-long, h, -demi_p); angle = PI
					3: pos = Vector3(-demi_l, h, long); angle = -PI / 2.0
				var modele: String = murs_pleins[_rng.randi_range(0, murs_pleins.size() - 1)]
				var fenetre := false
				if cote == 1 and etage == 0 and i == porte:
					modele = prefixe + "Door_Flat"
				elif (cote == 1 and _rng.randf() < 0.8) or (cote % 2 == 0 and _rng.randf() < 0.5):
					modele = prefixe + "Window_Wide_Flat"
					fenetre = true
				var mur := Modeles.creer(modele)
				mur.position = pos
				mur.rotation.y = angle
				maison.add_child(mur)
				if fenetre:
					_fenetre_allumee(maison, pos, angle)
				if modele.ends_with("Door_Flat"):
					var battant := Modeles.creer("Door_1_Flat")
					battant.position = pos + Basis(Vector3.UP, angle) * Vector3(-0.53, 0, 0)
					battant.rotation.y = angle
					maison.add_child(battant)
		for coin in [Vector3(demi_l, h, demi_p), Vector3(-demi_l, h, demi_p), Vector3(demi_l, h, -demi_p), Vector3(-demi_l, h, -demi_p)]:
			var poteau := Modeles.creer("Corner_Exterior_Brick" if briques else "Corner_Exterior_Wood")
			poteau.position = coin
			maison.add_child(poteau)
	# Le toit de tuiles et ses deux pignons.
	var haut := etages * 3.0
	var toit := Modeles.creer("Roof_RoundTiles_%dx%d" % [largeur, profondeur])
	toit.position = Vector3(0, haut, 0)
	maison.add_child(toit)
	for bout in [1.0, -1.0]:
		var pignon := Modeles.creer("Roof_Front_Brick%d" % largeur)
		pignon.position = Vector3(0, haut, bout * demi_p)
		pignon.rotation.y = 0.0 if bout > 0.0 else PI
		maison.add_child(pignon)
	if nom == "Maison du chef" or nom == "Forge":
		var cheminee := Modeles.creer("Prop_Chimney")
		cheminee.position = Vector3(-demi_l + 0.9, haut + 0.4, demi_p - 1.2)
		maison.add_child(cheminee)
	# La porte de chaque maison (pour les sentiers), et celle du chef qu'on passe avec E.
	_portes[nom] = [maison.to_global(Vector3(demi_l, 0, demi_p - 1.0 - porte * 2.0)), maison.global_basis.x.normalized()]
	_maisons[nom] = maison
	if nom == "Maison du chef":
		_porte_chef = maison.to_global(Vector3(demi_l, 0, demi_p - 1.0 - porte * 2.0))
		_devant_chef = maison.global_basis.x.normalized()
		var lanterne := Modeles.creer("Lantern_Wall")
		lanterne.position = Vector3(demi_l + 0.1, 2.6, demi_p - 1.0 - porte * 2.0 + 1.3)
		lanterne.rotation.y = PI / 2.0
		maison.add_child(lanterne)
		var lumiere := OmniLight3D.new()
		lumiere.light_color = COULEUR_FENETRE
		lumiere.light_energy = 1.0
		lumiere.omni_range = 6.0
		lumiere.position = lanterne.position + Vector3(0.6, -0.2, 0)
		maison.add_child(lumiere)
	# Un peu de lierre, des tonneaux ou des caisses contre les murs (au hasard).
	if _rng.randf() < 0.6:
		var lierre := Modeles.creer(["Prop_Vine1", "Prop_Vine4"][_rng.randi_range(0, 1)], Modeles.OBJETS, Color(0.42, 0.5, 0.52))
		lierre.position = Vector3(-demi_l - 0.2, haut - 0.2, _rng.randf_range(-demi_p + 0.8, demi_p - 0.8))
		lierre.rotation.y = -PI / 2.0
		maison.add_child(lierre)
	for k in _rng.randi_range(1, 3):
		var objet := Modeles.creer(["Barrel", "Crate_Wooden", "Prop_Crate"][_rng.randi_range(0, 2)])
		var cote := -1.0 if _rng.randf() < 0.5 else 1.0
		objet.position = Vector3(_rng.randf_range(-demi_l + 0.6, demi_l - 0.6), 0, cote * (demi_p + 0.5))
		objet.rotation.y = _rng.randf_range(0.0, TAU)
		maison.add_child(objet)
	# On ne traverse pas les murs.
	var forme := BoxShape3D.new()
	forme.size = Vector3(largeur, 3.0, profondeur) * ECHELLE_MAISONS
	_obstacle(forme, Transform3D(Basis(Vector3.UP, maison.rotation.y), maison.position + Vector3(0, 1.5 * ECHELLE_MAISONS, 0)))


## Une fenêtre éclairée de l'intérieur : le cadre, une lueur chaude derrière, parfois des
## volets ouverts, et une petite lumière qui éclaire le sol devant. Une fenêtre sur quatre
## reste noire (personne dans la pièce) : le village garde des coins d'ombre.
func _fenetre_allumee(maison: Node3D, pos: Vector3, angle: float) -> void:
	var tourne := Basis(Vector3.UP, angle)
	var cadre := Modeles.creer("Window_Wide_Flat1")
	cadre.position = pos
	cadre.rotation.y = angle
	maison.add_child(cadre)
	var eteinte := _rng.randf() < 0.25
	var lueur := MeshInstance3D.new()
	var plan := QuadMesh.new()
	plan.size = Vector2(1.3, 1.2)
	lueur.mesh = plan
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.03, 0.03, 0.045) if eteinte else COULEUR_FENETRE * (0.6 + _rng.randf() * 0.4)
	lueur.material_override = mat
	lueur.position = pos + tourne * Vector3(0, 1.72, -0.12)
	lueur.rotation.y = angle
	lueur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	maison.add_child(lueur)
	if _rng.randf() < 0.4:
		var volets := Modeles.creer("WindowShutters_Wide_Flat_Open")
		volets.position = pos
		volets.rotation.y = angle
		maison.add_child(volets)
	var lumiere := OmniLight3D.new()
	lumiere.light_color = COULEUR_FENETRE
	lumiere.light_energy = _rng.randf_range(0.45, 0.75)
	lumiere.omni_range = 3.5
	lumiere.position = pos + tourne * Vector3(0, 1.4, 0.9)
	if eteinte:
		lumiere.free()
	else:
		maison.add_child(lumiere)


# --- La forge, le puits, l'étal… ----------------------------------------------------

## Le poste du forgeron, devant la forge et tourné vers la place : l'établi (derrière
## lequel il se tient), l'enclume et la pierre à aiguiser de chaque côté, le râtelier
## d'armes et le foyer rougeoyant. C'est là qu'on lui achètera armes et armures.
func _creer_forge(x: float, y: float) -> void:
	var maison := Chemin.bruneval(x, y)
	var vers_place := (Chemin.VILLAGE - maison).normalized()
	var cote := Vector3(-vers_place.z, 0, vers_place.x)
	var poste := maison + vers_place * 3.6
	_devant_forge = poste + vers_place * 1.1
	var face := _vers(poste, Chemin.VILLAGE)
	var etabli := Modeles.creer("Workbench")
	etabli.position = poste
	etabli.rotation.y = face
	add_child(etabli)
	var forme := BoxShape3D.new()
	forme.size = Vector3(2.0, 0.9, 1.0)
	_obstacle(forme, Transform3D(Basis(Vector3.UP, face), poste + Vector3(0, 0.45, 0)))
	var enclume := Modeles.creer("Anvil")
	enclume.position = poste + cote * 1.7 + vers_place * 0.2
	enclume.rotation.y = face + 0.3
	add_child(enclume)
	_obstacle_rond(enclume.position, 0.45)
	# Le forgeron se tient derrière l'enclume, face à la place, et y frappe le métal.
	_poste_forgeron = enclume.position - vers_place * 0.68
	_enclume_forge = enclume.position
	var meule := Modeles.creer("Whetstone")
	meule.position = poste - cote * 1.8
	meule.rotation.y = face - 0.4
	add_child(meule)
	_obstacle_rond(meule.position, 0.5)
	var armes := Modeles.creer("WeaponStand")
	armes.position = poste - cote * 3.1 - vers_place * 0.8
	armes.rotation.y = face + 0.5
	add_child(armes)
	# Le foyer : un bloc de briques dont le dessus rougeoie.
	var foyer := MeshInstance3D.new()
	var bloc := BoxMesh.new()
	bloc.size = Vector3(1.0, 0.8, 1.0)
	foyer.mesh = bloc
	foyer.material_override = Modeles.materiau_de("Wall_UnevenBrick_Straight")
	foyer.position = poste + cote * 3.0 - vers_place * 0.9 + Vector3(0, 0.4, 0)
	add_child(foyer)
	var braise := MeshInstance3D.new()
	var dessus := BoxMesh.new()
	dessus.size = Vector3(0.7, 0.04, 0.7)
	braise.mesh = dessus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ff6a1f")
	braise.material_override = mat
	braise.position = foyer.position + Vector3(0, 0.41, 0)
	add_child(braise)
	var lumiere := OmniLight3D.new()
	lumiere.light_color = Color("ff7a30")
	lumiere.omni_range = 6.0
	lumiere.position = foyer.position + Vector3(0, 0.9, 0)
	add_child(lumiere)
	_feux.append(lumiere)
	_obstacle_rond(foyer.position, 0.6)


## Le puits : une margelle de pierres, deux poteaux, une traverse, un seau et sa corde.
func _creer_puits(x: float, y: float) -> void:
	var centre := Chemin.bruneval(x, y)
	var pierre := Modeles.materiau_de("Wall_UnevenBrick_Straight")
	var margelle := MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.75
	tube.bottom_radius = 0.8
	tube.height = 0.8
	tube.radial_segments = 14
	margelle.mesh = tube
	margelle.material_override = pierre
	margelle.position = centre + Vector3(0, 0.4, 0)
	add_child(margelle)
	var trou := MeshInstance3D.new()
	var disque := CylinderMesh.new()
	disque.top_radius = 0.6
	disque.bottom_radius = 0.6
	disque.height = 0.02
	trou.mesh = disque
	var noir := StandardMaterial3D.new()
	noir.albedo_color = Color("07090c")
	trou.material_override = noir
	trou.position = centre + Vector3(0, 0.81, 0)
	add_child(trou)
	var bois := Modeles.materiau_de("Floor_WoodDark")
	var travers := Vector3(1, 0, 0).rotated(Vector3.UP, _rng.randf_range(0.0, PI))
	for s in [-1.0, 1.0]:
		add_child(_poutre(centre + travers * s * 0.85, centre + travers * s * 0.85 + Vector3(0, 2.0, 0), 0.07, bois))
	add_child(_poutre(centre - travers * 1.0 + Vector3(0, 1.85, 0), centre + travers * 1.0 + Vector3(0, 1.85, 0), 0.06, bois))
	var seau := Modeles.creer("Bucket_Wooden_1")
	seau.position = centre + Vector3(0, 0.82, 0) + travers.cross(Vector3.UP) * 0.55
	add_child(seau)
	var corde := Modeles.creer("Rope_1")
	corde.position = centre + Vector3(0, 1.75, 0)
	corde.scale = Vector3.ONE * 0.6
	add_child(corde)
	_obstacle_rond(centre, 0.85)


## L'étal du médecin, devant sa maison et tourné vers la place : des potions et des
## flacons sur le comptoir, une étagère de fioles, un chaudron qui fume doucement. C'est là
## qu'on lui achètera des potions.
func _creer_etal_medecin(x: float, y: float) -> void:
	var maison := Chemin.bruneval(x, y)
	var vers_place := (Chemin.VILLAGE - maison).normalized()
	var cote := Vector3(-vers_place.z, 0, vers_place.x)
	var poste := maison + vers_place * 3.7
	_devant_medecin = poste + vers_place * 1.1
	var face := _vers(poste, Chemin.VILLAGE)
	var tourne := Basis(Vector3.UP, face)
	var etal := Modeles.creer("Stall_Empty")
	etal.position = poste
	etal.rotation.y = face
	add_child(etal)
	_etal_medecin = etal
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.9, 1.0, 1.0)
	_obstacle(forme, Transform3D(tourne, poste + Vector3(0, 0.5, 0)))
	# La médecin se tient à côté de son étal, du côté de la caméra (derrière, le toit de
	# l'étal la cachait) ; le chaudron est de l'autre côté.
	_cote_medecin = cote if cote.dot(Chemin.HAUT_ECRAN) < 0.0 else -cote
	_poste_medecin = poste + _cote_medecin * 1.35 + vers_place * 0.15
	# Sur le comptoir (à 0,83 m, mesuré) : des potions et des petits flacons.
	var comptoir := 0.83
	for o in [["Potion_1", Vector3(-0.65, 0, 0.1)], ["Potion_2", Vector3(-0.4, 0, -0.05)], ["Potion_4", Vector3(-0.15, 0, 0.15)],
			["SmallBottles_1", Vector3(0.2, 0, 0.0)], ["Potion_2", Vector3(0.5, 0, 0.12)], ["Potion_1", Vector3(0.7, 0, -0.1)]]:
		var objet := Modeles.creer(o[0])
		objet.position = poste + tourne * o[1] + Vector3(0, comptoir, 0)
		objet.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(objet)
	var etagere := Modeles.creer("Shelf_Small_Bottles")
	etagere.position = poste - vers_place * 1.6 + Vector3(0, 1.1, 0)
	etagere.rotation.y = face
	add_child(etagere)
	var chaudron := Modeles.creer("Cauldron")
	chaudron.position = poste - _cote_medecin * 1.9 - vers_place * 0.3
	add_child(chaudron)
	_obstacle_rond(chaudron.position, 0.5)
	# Une lueur verdâtre très douce sort du chaudron.
	var lueur := OmniLight3D.new()
	lueur.light_color = Color("8fbf7a")
	lueur.light_energy = 0.5
	lueur.omni_range = 2.5
	lueur.position = chaudron.position + Vector3(0, 1.0, 0)
	add_child(lueur)


## Le chemin qui part de la place vers le haut de l'écran, entre la maison du chef et le
## médecin : la future sortie vers la Zone 1 (pas encore ouverte, la forêt la ferme).
func _chemin_de_sortie() -> void:
	_sentier(_points_sortie(), 1.3, 0.2, 0.03, 3.0, 6.0)


func _points_sortie() -> Array[Vector3]:
	return [Chemin.bruneval(4.5, 5.5), Chemin.bruneval(7.5, 11.0), Chemin.bruneval(9.5, 17.0),
		Chemin.bruneval(10.5, 23.0), Chemin.bruneval(11.0, 29.0)]


## Un sentier de terre battue (même matière que le grand chemin) le long des « points » :
## « demi » est sa demi-largeur, qui varie un peu le long du sentier ; « humidite » le rend
## boueux (1 = boue) ; il naît en dégradé sur « fondu_debut » mètres et s'efface sur
## « fondu_fin » mètres.
func _sentier(points: Array[Vector3], demi: float, humidite := 0.2, hauteur := 0.03, fondu_debut := 2.0, fondu_fin := 1.5) -> void:
	var courbe := Curve3D.new()
	courbe.bake_interval = 0.5
	for i in points.size():
		var avant: Vector3 = points[max(i - 1, 0)]
		var apres: Vector3 = points[min(i + 1, points.size() - 1)]
		courbe.add_point(points[i], -(apres - avant) * 0.25, (apres - avant) * 0.25)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/chemin.gdshader")
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cuits := courbe.get_baked_points()
	var longueur := courbe.get_baked_length()
	var travers := [-1.9, -1.2, -0.6, 0.0, 0.6, 1.2, 1.9]
	var parcouru := 0.0
	var decale := _rng.randf_range(0.0, 10.0)
	for i in cuits.size():
		if i > 0:
			parcouru += cuits[i].distance_to(cuits[i - 1])
		var tangente := (cuits[min(i + 1, cuits.size() - 1)] - cuits[max(i - 1, 0)]).normalized()
		var cote := Vector3(-tangente.z, 0.0, tangente.x)
		# Il s'élargit et se resserre un peu, comme un vrai passage.
		var largeur := demi * (1.0 + sin(parcouru * 0.55 + decale) * 0.15 + sin(parcouru * 1.7 + decale * 2.0) * 0.06)
		var apparition := smoothstep(0.0, fondu_debut, parcouru) * (1.0 - smoothstep(longueur - fondu_fin, longueur, parcouru))
		for u in travers:
			outil.set_color(Color(humidite, 0, 0, apparition))
			outil.set_normal(Vector3.UP)
			outil.set_uv(Vector2(u, parcouru))
			outil.add_vertex(cuits[i] + cote * u * largeur + Vector3(0, hauteur, 0))
	var n := travers.size()
	for i in cuits.size() - 1:
		for k in n - 1:
			var a := i * n + k
			outil.add_index(a)
			outil.add_index(a + 1)
			outil.add_index(a + n)
			outil.add_index(a + 1)
			outil.add_index(a + n + 1)
			outil.add_index(a + n)
	var bande := MeshInstance3D.new()
	bande.mesh = outil.commit()
	bande.material_override = mat
	bande.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bande)


# --- Le sol du village (étape 1 du plan d'amélioration) ---------------------------------

## La terre tassée de l'enceinte : le shader du sol la dessine dans l'ovale de la clairière.
func _regler_le_sol() -> void:
	var sol := get_tree().root.find_child("Sol", true, false)
	var apparence := sol.get_node_or_null("Apparence") as MeshInstance3D if sol else null
	if apparence == null or not apparence.material_override is ShaderMaterial:
		return
	var mat := apparence.material_override as ShaderMaterial
	mat.set_shader_parameter("village_origine", Vector2(Chemin.ORIGINE_BRUNEVAL.x, Chemin.ORIGINE_BRUNEVAL.z))
	mat.set_shader_parameter("village_droite", Vector2(Chemin.DROITE_ECRAN.x, Chemin.DROITE_ECRAN.z))
	mat.set_shader_parameter("village_haut", Vector2(Chemin.HAUT_ECRAN.x, Chemin.HAUT_ECRAN.z))
	mat.set_shader_parameter("village_demi", Vector2(Chemin.DEMI_LARGEUR_BRUNEVAL, Chemin.DEMI_HAUTEUR_BRUNEVAL))
	mat.set_shader_parameter("village_centre_y", Chemin.CENTRE_Y_BRUNEVAL)


## Des traces de pas dans la boue : là où Élise passe avec son eau (du puits à la
## médecin), et devant les portes et les stands, là où l'on va et vient.
func _creer_traces_de_pas() -> void:
	var places: Array[Transform3D] = []
	var trajets := [[Chemin.bruneval(-2.7, 3.3), Chemin.bruneval(5.8, 4.4)]]
	for but in [_devant_forge, _devant_medecin, _portes["Maison du chef"][0], _portes["Abri"][0], _portes["Abri de l'est"][0]]:
		var vers: Vector3 = (Chemin.VILLAGE - but)
		vers.y = 0.0
		trajets.append([but + vers.normalized() * 0.6, but + vers.normalized() * 3.2])
	for trajet in trajets:
		var a: Vector3 = trajet[0]
		var b: Vector3 = trajet[1]
		var direction := (b - a).normalized()
		var travers := Vector3(-direction.z, 0, direction.x)
		var pas := int(a.distance_to(b) / 0.42)
		for i in pas:
			# Un pied à gauche, un pied à droite, pas tout à fait réguliers.
			var cote := 0.11 if i % 2 == 0 else -0.11
			var ou := a + direction * (i * 0.42 + _rng.randf_range(-0.05, 0.05)) + travers * cote
			var angle := atan2(direction.x, direction.z) + _rng.randf_range(-0.2, 0.2)
			places.append(Transform3D(Basis(Vector3.UP, angle), ou + Vector3(0, 0.045, 0)))
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.13, 0.3)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/traces_de_pas.gdshader")
	quad.material = mat
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = quad
	multi.instance_count = places.size()
	for i in places.size():
		multi.set_instance_transform(i, places[i])
		# Certaines traces sont presque effacées.
		multi.set_instance_color(i, Color(1, 1, 1, _rng.randf_range(0.35, 1.0)))
	var traces := MultiMeshInstance3D.new()
	traces.name = "Traces de pas"
	traces.multimesh = multi
	traces.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(traces)


## Trois petites flaques mates : sur le chemin d'arrivée, au bord de la place, et près de
## l'abri de l'est (là où l'eau d'Élise déborde).
func _creer_flaques() -> void:
	for f in [[Vector2(0.9, -11.6), Vector2(1.7, 1.1)], [Vector2(-5.6, -0.6), Vector2(1.2, 0.9)], [Vector2(7.2, -5.6), Vector2(1.4, 1.0)]]:
		var flaque := MeshInstance3D.new()
		var plan := PlaneMesh.new()
		plan.size = f[1]
		flaque.mesh = plan
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/flaque.gdshader")
		mat.set_shader_parameter("graine", _rng.randf_range(0.0, 50.0))
		flaque.material_override = mat
		flaque.position = Chemin.bruneval(f[0].x, f[0].y) + Vector3(0, 0.04, 0)
		flaque.rotation.y = _rng.randf_range(0.0, TAU)
		flaque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(flaque)


## Le rempart (demande de Tom) : des pieux de bois taillés en pointe, serrés tout autour de
## la clairière, tenus par deux traverses côté village. Il s'ouvre là où arrive le chemin ;
## sur le chemin de sortie, une porte de planches reste fermée (la Zone 1 n'existe pas
## encore). On ne le traverse pas.
func _creer_rempart() -> void:
	# Le bois des maisons du pack (T_WoodTrim) : le fil du bois court le long du pieu, et la
	# pointe taillée montre le bois coupé, plus clair.
	var ecorce := StandardMaterial3D.new()
	ecorce.albedo_texture = load("res://assets/objets/T_WoodTrim_BaseColor.png")
	ecorce.normal_enabled = true
	ecorce.normal_texture = load("res://assets/objets/T_WoodTrim_Normal.png")
	ecorce.albedo_color = Color(0.78, 0.72, 0.7)
	ecorce.roughness = 1.0
	# Les gros poteaux et les planches des portes : de l'écorce, dont le relief court en long.
	var bois_porte := StandardMaterial3D.new()
	bois_porte.albedo_texture = load("res://assets/nature/Bark_NormalTree.png")
	bois_porte.normal_enabled = true
	bois_porte.normal_texture = load("res://assets/nature/Bark_NormalTree_Normal.png")
	bois_porte.albedo_color = Color(0.62, 0.5, 0.44)
	bois_porte.uv1_scale = Vector3(1.0, 1.5, 1.0)
	bois_porte.roughness = 1.0
	# Un pieu : un tronc fin et sa pointe, en un seul maillage, répété avec un MultiMesh.
	# Dans la texture : le fil du bois foncé est entre v = 0,33 et 0,6 (horizontal, donc u
	# suit la hauteur du pieu) ; le bois coupé est vers u = 0,25, v = 0,7.
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cotes := 7
	for i in cotes:
		var a := TAU * i / cotes
		var b := TAU * (i + 1) / cotes
		var pa := Vector3(cos(a), 0, sin(a)) * 0.17
		var pb := Vector3(cos(b), 0, sin(b)) * 0.17
		var h := Vector3.UP * 2.3
		var pointe := Vector3.UP * 2.75
		var va := lerpf(0.34, 0.6, float(i) / cotes)
		var vb := lerpf(0.34, 0.6, float(i + 1) / cotes)
		var decale := float(i % 3) * 0.3
		for v in [[pa, Vector2(decale, va)], [pa + h, Vector2(decale + 0.9, va)], [pb + h, Vector2(decale + 0.9, vb)],
				[pa, Vector2(decale, va)], [pb + h, Vector2(decale + 0.9, vb)], [pb, Vector2(decale, vb)],
				[pa + h, Vector2(0.19, 0.66)], [pointe, Vector2(0.25, 0.76)], [pb + h, Vector2(0.31, 0.66)]]:
			outil.set_uv(v[1])
			outil.add_vertex(v[0])
	outil.generate_normals()
	outil.generate_tangents()
	var pieu := outil.commit()
	pieu.surface_set_material(0, ecorce)
	# Les places des pieux, tous les 0,36 m le long du bord de la clairière.
	var sortie := [Chemin.bruneval(4.5, 5.5), Chemin.bruneval(7.5, 11.0), Chemin.bruneval(9.5, 17.0)]
	var places: Array[Transform3D] = []
	var porte := Vector3.INF
	var fin_porte := Vector3.INF
	var entree: Array[Vector3] = []
	var teintes: Array[Color] = []
	var pas := 400
	var avant := Chemin.bord_bruneval(0.0, 0.3)
	var depuis := 0.0
	var debut_mur := Vector3.INF
	for i in pas + 1:
		var p := Chemin.bord_bruneval(TAU * i / pas, 0.3)
		depuis += p.distance_to(avant)
		var ouvert := Chemin.distance_au_chemin(p) < 2.6
		if ouvert:
			entree.append(p)
		if _distance_a(p, sortie) < 1.8:
			if porte == Vector3.INF:
				porte = p
			fin_porte = p
			ouvert = true
		# Le mur invisible suit les pieux, par tronçons.
		if ouvert and debut_mur != Vector3.INF:
			_mur(debut_mur, avant)
			debut_mur = Vector3.INF
		elif not ouvert and debut_mur == Vector3.INF:
			debut_mur = p
		elif not ouvert and debut_mur.distance_to(p) > 4.0:
			_mur(debut_mur, p)
			debut_mur = p
		if not ouvert and depuis >= 0.36:
			depuis = 0.0
			# Des pieux inégaux, plus ou moins penchés ; quelques-uns cassés à mi-hauteur
			# (attaques passées), et quelques pieux neufs, plus clairs, qui les remplacent.
			var penche := Basis(Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized(), _rng.randf_range(0.0, 0.09))
			var hauteur := _rng.randf_range(0.8, 1.16)
			var teinte := Color(1, 1, 1) * _rng.randf_range(0.85, 1.05)
			var etat := _rng.randf()
			if etat < 0.04:
				hauteur = _rng.randf_range(0.45, 0.6)
			elif etat < 0.1:
				teinte = Color(1.35, 1.22, 1.08)
			places.append(Transform3D(penche * Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(Vector3(1.0, hauteur, 1.0)), p))
			teintes.append(teinte)
		avant = p
	if debut_mur != Vector3.INF:
		_mur(debut_mur, avant)
	ecorce.vertex_color_use_as_albedo = true
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = pieu
	multi.instance_count = places.size()
	for i in places.size():
		multi.set_instance_transform(i, places[i])
		multi.set_instance_color(i, teintes[i])
	var rempart := MultiMeshInstance3D.new()
	rempart.name = "Rempart"
	rempart.multimesh = multi
	rempart.set_meta("pieux", places)
	add_child(rempart)
	# Deux traverses côté village, par tronçons, pour tenir les pieux (pas partout, et pas
	# toutes à la même hauteur : elles ont été posées au fil des réparations).
	var bois := Modeles.materiau_de("Floor_WoodDark")
	for i in range(0, places.size() - 1, 6):
		var a := places[i].origin
		var b := places[mini(i + 6, places.size() - 1)].origin
		if a.distance_to(b) > 3.0 or _rng.randf() < 0.18:
			continue
		var dedans := (Chemin.VILLAGE - (a + b) / 2.0).normalized() * 0.22
		for hauteur in [0.7, 1.8]:
			var h1: float = hauteur + _rng.randf_range(-0.1, 0.1)
			var h2: float = hauteur + _rng.randf_range(-0.1, 0.1)
			add_child(_poutre(a + dedans + Vector3.UP * h1, b + dedans + Vector3.UP * h2, 0.06, bois))
	# L'entrée, là où arrive le chemin : deux gros poteaux et une traverse au-dessus.
	# Bran est adossé au poteau de droite.
	var bout_a := entree[0]
	var bout_b := entree[0]
	for p in entree:
		for q in entree:
			if p.distance_to(q) > bout_a.distance_to(bout_b):
				bout_a = p
				bout_b = q
	var milieu := (bout_a + bout_b) / 2.0
	var ecart := (bout_b - bout_a).normalized()
	var gauche_entree := milieu - ecart * (bout_a.distance_to(bout_b) / 2.0 + 0.25)
	var droite_entree := milieu + ecart * (bout_a.distance_to(bout_b) / 2.0 + 0.25)
	if (droite_entree - gauche_entree).dot(Chemin.DROITE_ECRAN) < 0.0:
		var echange := gauche_entree
		gauche_entree = droite_entree
		droite_entree = echange
	for poteau in [gauche_entree, droite_entree]:
		add_child(_poutre(poteau, poteau + Vector3.UP * 3.4, 0.24, bois_porte))
		_obstacle_rond(poteau, 0.3)
	add_child(_poutre(gauche_entree + Vector3.UP * 3.15 - ecart * 0.4, droite_entree + Vector3.UP * 3.15 + ecart * 0.4, 0.14, bois_porte))
	_poteau_entree = droite_entree
	# Une torche sur chaque poteau, tournée vers le chemin qui arrive de la forêt.
	var dehors := (milieu - Chemin.VILLAGE)
	dehors.y = 0.0
	dehors = dehors.normalized()
	for poteau in [gauche_entree, droite_entree]:
		var torche := Modeles.creer("Torch_Metal")
		torche.basis = Basis(Vector3.UP, atan2(dehors.x, dehors.z))
		torche.position = poteau + dehors * 0.26 + Vector3.UP * 2.2
		add_child(torche)
		var flamme: MeshInstance3D = get_parent()._flamme(0.12, 0.4)
		flamme.position = poteau + dehors * 0.56 + Vector3.UP * 2.55
		add_child(flamme)
		var lumiere := OmniLight3D.new()
		lumiere.light_color = Color("e0823a")
		lumiere.light_energy = 1.6
		lumiere.omni_range = 7.0
		lumiere.position = flamme.position + Vector3(0, 0.2, 0)
		add_child(lumiere)
	# La porte fermée sur le chemin de sortie : des planches entre deux gros poteaux.
	if porte != Vector3.INF:
		var centre := (porte + fin_porte) / 2.0
		var travers := (fin_porte - porte).normalized()
		var demi := porte.distance_to(fin_porte) / 2.0 + 0.2
		var gauche := centre - travers * demi
		var droite := centre + travers * demi
		for poteau in [gauche, droite]:
			add_child(_poutre(poteau, poteau + Vector3.UP * 3.2, 0.24, bois_porte))
		var planches := int(demi / 0.38) * 2 + 1
		for k in planches:
			var x := lerpf(-demi + 0.2, demi - 0.2, k / float(planches - 1))
			add_child(_poutre(centre + travers * x, centre + travers * x + Vector3.UP * _rng.randf_range(2.35, 2.55), 0.17, bois_porte))
		for hauteur in [0.6, 1.9]:
			add_child(_poutre(gauche + Vector3.UP * hauteur, droite + Vector3.UP * hauteur, 0.08, bois))
		_mur(gauche, droite)


# --- L'identité des lieux, les lanternes, la vie du village ---------------------------

## Un point près d'une maison, donné dans ses propres repères : x vers la façade (la
## porte), z le long de la façade. Les mesures sont celles du pack (avant la réduction).
func _pres(nom: String, x: float, z: float) -> Vector3:
	var maison: Node3D = _maisons[nom]
	return maison.to_global(Vector3(x, 0, z))


func _angle(nom: String) -> float:
	return (_maisons[nom] as Node3D).rotation.y


## Pose un objet du pack (teinté vers la palette) ; « rayon » > 0 : on ne le traverse pas.
func _objet(nom: String, ou: Vector3, angle := 0.0, rayon := 0.0, teinte := Modeles.TEINTE_OBJETS, dossier := Modeles.OBJETS) -> Node3D:
	var objet := Modeles.creer(nom, dossier, teinte)
	objet.position = ou
	objet.rotation.y = angle
	add_child(objet)
	if rayon > 0.0:
		_obstacle_rond(ou, rayon)
	return objet


## La forge : sacs de charbon, seau et tonneau d'eau pour tremper le métal, pioche et hache
## appuyées au mur, chaîne au sol. Le foyer brille plus fort.
func _decorer_forge() -> void:
	var nom := "Forge"
	for k in 2:
		_objet("Bag", _pres(nom, 1.2 + k * 0.6, -2.8 - k * 0.15), _angle(nom) + _rng.randf_range(-0.6, 0.6), 0.3, Color(0.22, 0.21, 0.24))
	_objet("Bucket_Wooden_1", _pres(nom, 3.1, -2.2), 0.0, 0.25)
	_objet("Barrel", _pres(nom, 0.4, 2.75), 0.0, 0.4)
	var pioche := _objet("Pickaxe_Bronze", _pres(nom, 2.25, 1.7) + Vector3.UP * 0.55, _angle(nom) + PI / 2.0)
	pioche.rotation.z = 0.25
	var hache := _objet("Axe_Bronze", _pres(nom, 2.25, 0.9) + Vector3.UP * 0.38, _angle(nom) + PI / 2.0)
	hache.rotation.z = -0.2
	_objet("Chain_Coil", _devant_forge + (Chemin.VILLAGE - _devant_forge).normalized() * -0.4 + Basis(Vector3.UP, _angle(nom)) * Vector3(0, 0, -1.6) + Vector3.UP * 0.01, _rng.randf_range(0.0, TAU))
	for lumiere in _feux:
		lumiere.omni_range = 7.5


## La médecin : des bouquets de plantes séchées pendus sous l'auvent de son étal, une caisse
## de fioles, un pot et un sac d'herbes, un seau près du chaudron.
func _decorer_medecin() -> void:
	var etal := _etal_medecin
	for x in [-0.66, -0.3, 0.08, 0.46]:
		var bouquet := Modeles.creer("Grass_Wispy_Tall", Modeles.NATURE, Color(0.62, 0.55, 0.42))
		bouquet.scale = Vector3.ONE * _rng.randf_range(0.28, 0.36)
		bouquet.rotation = Vector3(PI, _rng.randf_range(0.0, TAU), 0)
		bouquet.position = Vector3(x, 1.98, 0.32)
		etal.add_child(bouquet)
	var tourne := Basis(Vector3.UP, etal.rotation.y)
	# Tout va du côté du chaudron, loin de la médecin (« s » : son côté, en x de l'étal).
	var s := signf((tourne * Vector3.RIGHT).dot(_cote_medecin))
	var caisse := _objet("Crate_Wooden", etal.position + tourne * Vector3(-s * 2.75, 0, -0.85), etal.rotation.y + 0.2, 0.4)
	for k in 3:
		_objet("SmallBottle", caisse.position + Vector3.UP * 0.62 + tourne * Vector3(-0.15 + k * 0.14, 0, _rng.randf_range(-0.08, 0.08)), _rng.randf_range(0.0, TAU), 0.0, Color(0.6, 0.72, 0.62))
	_objet("Vase_2", etal.position + tourne * Vector3(-s * 2.85, 0, 0.45), 0.0, 0.35)
	_objet("Bag", etal.position + tourne * Vector3(-s * 3.5, 0, -0.2), _rng.randf_range(0.0, TAU), 0.3, Color(0.42, 0.46, 0.38))
	_objet("Bucket_Metal", etal.position + tourne * Vector3(-s * 1.6, 0, 0.85), 0.0, 0.25)


## La maison du chef : une deuxième lanterne de l'autre côté de la porte, une bannière
## sur la façade, un banc sous la fenêtre et un tonneau d'eau au coin.
func _decorer_chef() -> void:
	var nom := "Maison du chef"
	var maison: Node3D = _maisons[nom]
	var porte := maison.to_local(_porte_chef).z
	var lanterne := Modeles.creer("Lantern_Wall")
	lanterne.position = Vector3(2.1, 2.6, porte - 1.3)
	lanterne.rotation.y = PI / 2.0
	maison.add_child(lanterne)
	var lumiere := OmniLight3D.new()
	lumiere.light_color = COULEUR_FENETRE
	lumiere.light_energy = 0.9
	lumiere.omni_range = 5.0
	lumiere.position = lanterne.position + Vector3(0.6, -0.2, 0)
	maison.add_child(lumiere)
	var cote := -1.0 if porte >= 0.0 else 1.0
	var banniere := Modeles.creer("Banner_1")
	banniere.position = Vector3(2.15, 2.85, porte + cote * 2.3)
	banniere.rotation.y = PI / 2.0
	maison.add_child(banniere)
	_objet("Bench", _pres(nom, 2.9, porte + cote * 2.3), _angle(nom) + PI / 2.0, 0.0)
	var forme := BoxShape3D.new()
	forme.size = Vector3(2.4, 0.5, 0.5)
	_obstacle(forme, Transform3D(Basis(Vector3.UP, _angle(nom) + PI / 2.0), _pres(nom, 2.9, porte + cote * 2.3) + Vector3.UP * 0.25))
	_objet("Barrel", _pres(nom, 2.6, -cote * 3.6), 0.0, 0.4)


## Les abris : à l'ouest, un tonneau, une hache appuyée au mur, un tabouret et un panier
## devant ; à l'est, des tonneaux, un panier, une corde et le seau d'Élise.
func _decorer_abris() -> void:
	# (Les objets devant la façade vont du côté opposé à la porte, pour ne pas la gêner.)
	var ouest := "Abri"
	var cote_ouest := -signf(_cote_de_la_porte(ouest))
	_objet("Barrel", _pres(ouest, -0.3, -2.75), 0.3, 0.4)
	var hache := _objet("Axe_Bronze", _pres(ouest, 1.2, -2.25) + Vector3.UP * 0.38, _angle(ouest))
	hache.rotation.z = 0.2
	_objet("Stool", _pres(ouest, 2.9, cote_ouest * 1.5), _rng.randf_range(0.0, TAU), 0.25)
	_objet("FarmCrate_Empty", _pres(ouest, 2.7, cote_ouest * 2.5), _angle(ouest) + 0.3)
	var est := "Abri de l'est"
	var cote_est := -signf(_cote_de_la_porte(est))
	_objet("Barrel", _pres(est, -0.8, 2.75), 0.0, 0.4)
	_objet("Barrel", _pres(est, 0.1, 2.85), 0.6, 0.4)
	_objet("FarmCrate_Empty", _pres(est, 2.8, cote_est * 2.5), _angle(est) - 0.4)
	_objet("Rope_2", _pres(est, 1.6, 2.9) + Vector3.UP * 0.01, _rng.randf_range(0.0, TAU))
	_objet("Bucket_Wooden_1", _pres(est, 2.9, cote_est * 1.4), 0.0, 0.25)


## Où est la porte le long de la façade (z dans les repères de la maison).
func _cote_de_la_porte(nom: String) -> float:
	var z: float = (_maisons[nom] as Node3D).to_local(_portes[nom][0]).z
	return z if absf(z) > 0.01 else 1.0



## Des lanternes accrochées à la façade de la forge, de la médecin et de l'abri ouest, à
## côté de la porte : une lumière chaude et locale là où l'on passe.
func _creer_lanternes() -> void:
	for nom in ["Forge", "Médecin", "Abri"]:
		var maison: Node3D = _maisons[nom]
		var porte := _cote_de_la_porte(nom)
		var lanterne := Modeles.creer("Lantern_Wall")
		lanterne.position = Vector3(2.1, 2.5, porte - signf(porte) * 1.3)
		lanterne.rotation.y = PI / 2.0
		maison.add_child(lanterne)
		var lumiere := OmniLight3D.new()
		lumiere.light_color = Color("f0a75a")
		lumiere.light_energy = 1.0
		lumiere.omni_range = 6.0
		lumiere.position = lanterne.position + Vector3(0.6, -0.2, 0)
		maison.add_child(lumiere)


## Les signes de la vie des survivants, chacun à sa place : la charrette qui a ramené le
## bois et sa caisse, les seaux au pied du puits.
func _creer_vie_du_village() -> void:
	# La charrette, rangée contre le rempart à l'ouest.
	var charrette := Chemin.bruneval(-15.2, -2.6)
	var long := (Chemin.bord_bruneval(-PI / 2.0 + 0.15) - Chemin.bord_bruneval(-PI / 2.0 - 0.15)).normalized()
	_objet("Prop_Wagon", charrette, atan2(long.x, long.z) + 0.15)
	var forme := BoxShape3D.new()
	forme.size = Vector3(2.0, 1.5, 4.0)
	_obstacle(forme, Transform3D(Basis(Vector3.UP, atan2(long.x, long.z) + 0.15), charrette + long * -1.15 + Vector3.UP * 0.75))
	_objet("Crate_Wooden", charrette + Vector3(-long.z, 0, long.x).normalized() * 1.4, 0.4, 0.4)
	_objet("Crate_Wooden", Chemin.bruneval(-8.0, 12.2), 0.3, 0.4)
	_objet("Barrel", Chemin.bruneval(-6.9, 12.6), 0.0, 0.4)
	# Deux seaux au pied du puits.
	_objet("Bucket_Wooden_1", Chemin.bruneval(-4.7, 5.3), 0.0, 0.0)
	_objet("Bucket_Wooden_1", Chemin.bruneval(-4.4, 3.6), 0.8, 0.0)



## La plus petite distance (à plat) entre « p » et une ligne brisée.
func _distance_a(p: Vector3, ligne: Array) -> float:
	var meilleure := INF
	var q := Vector2(p.x, p.z)
	for i in ligne.size() - 1:
		var a := Vector2(ligne[i].x, ligne[i].z)
		var b := Vector2(ligne[i + 1].x, ligne[i + 1].z)
		var t := clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		meilleure = minf(meilleure, q.distance_to(a + (b - a) * t))
	return meilleure


## Un mur invisible de « a » à « b » (on ne traverse pas le rempart).
func _mur(a: Vector3, b: Vector3) -> void:
	var direction := b - a
	direction.y = 0.0
	if direction.length() < 0.05:
		return
	var forme := BoxShape3D.new()
	forme.size = Vector3(0.5, 3.0, direction.length() + 0.3)
	_obstacle(forme, Transform3D(Basis.looking_at(direction.normalized()), (a + b) / 2.0 + Vector3(0, 1.5, 0)))


func _creer_etal(x: float, y: float) -> void:
	var pos := Chemin.bruneval(x, y)
	var etal := Modeles.creer("Stall_Empty")
	etal.position = pos
	# L'étal regarde le chemin, un peu de travers.
	etal.rotation.y = _vers(pos, Chemin.bruneval(0.0, -9.0)) + 0.25
	add_child(etal)
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.9, 1.2, 1.0)
	_obstacle(forme, Transform3D(Basis(Vector3.UP, etal.rotation.y), pos + Vector3(0, 0.6, 0)))
	# Osric se tient devant son étal, du côté des passants (demande de Tom).
	var devant := Basis(Vector3.UP, etal.rotation.y) * Vector3.BACK
	_poste_osric = pos + devant * 1.25
	_regard_osric = pos + devant * 6.0
	for o in [["FarmCrate_Apple", Vector3(1.4, 0, 0.5)], ["FarmCrate_Carrot", Vector3(-1.5, 0, 0.3)], ["Barrel_Apples", Vector3(1.2, 0, -0.7)]]:
		var objet := Modeles.creer(o[0])
		objet.position = pos + Basis(Vector3.UP, etal.rotation.y) * o[1]
		objet.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(objet)


# --- Les survivants -------------------------------------------------------------------


## Les habitants : chacun a sa silhouette (costaud, mince, petit…), sa place, son activité,
## ses petits gestes et ses répliques (proposées par Claude, à valider par Tom : on peut
## les changer ici). Certains flânent sur la place, d'un point à l'autre.
func _creer_survivants() -> void:
	# Les endroits où l'on flâne, en tour autour de la place (sans passer sur le feu, les
	# bancs, le puits ni les étals).
	var balade: Array[Vector3] = []
	for p in [Vector2(0.0, -6.8), Vector2(3.6, -6.0), Vector2(6.0, -3.3), Vector2(4.6, 0.2), Vector2(3.2, 6.2),
			Vector2(1.2, 5.6), Vector2(-4.4, 0.4), Vector2(-5.2, -2.4), Vector2(-2.4, -6.7)]:
		balade.append(Chemin.bruneval(p.x, p.y))
	# Le chef du village, chez lui, derrière sa grande table, un petit « ! » au-dessus de
	# la tête : il a une quête à donner (la quête elle-même viendra plus tard).
	_survivant({"nom": "Aubert", "tenue": "Male_Peasant", "teinte": Color(0.42, 0.38, 0.46), "activite": "bras_croises",
		"coiffures": ["Hair_SimpleParted", "Hair_Beard"], "cheveux": Color(0.55, 0.53, 0.5), "quete": true,
		"taille": 1.03, "corpulence": 1.06, "gestes": ["Idle_Talking", "ual2/Yes"],
		"ou": _interieur.place_du_chef, "regard": _interieur.arrivee,
		"repliques": [
			"Entre, et ferme derrière toi. Le froid suit les vivants jusque sur le seuil.",
			"Je suis Aubert. Je tiens ce hameau debout, avec ce qu'il reste de nous.",
			"Bran dit que tu es sorti de la forêt sans un souvenir. Ici, on ne demande pas d'où l'on vient. On demande ce qu'on peut faire.",
			"J'aurai besoin de ton épée. Prépare-toi, puis reviens me voir : il faudra rouvrir la porte du nord.",
		]})
	# Les deux marchands, derrière leur stand, face à la place. Après la première
	# conversation, E ouvre directement leur boutique (voir boutiques.gd).
	# Le forgeron : un colosse, large et barbu, qui range ses outils.
	_survivant({"nom": "Le forgeron", "tenue": "Male_Peasant", "teinte": Color(0.34, 0.3, 0.28), "activite": "forge",
		"coiffures": ["Hair_Buzzed", "Hair_Beard"], "cheveux": Color(0.16, 0.12, 0.1),
		"taille": 1.06, "corpulence": 1.2, "ventre": 1.65, "gestes": ["Interact", "PickUp_Table"],
		"ou": _poste_forgeron, "regard": _enclume_forge, "frappe": _enclume_forge + Vector3.UP * 0.58,
		"boutique": "forgeron", "titre_boutique": "Armes et armures",
		"repliques": [
			"Des lames, des armures… Le métal ne manque pas. C'est le temps qui manque.",
			"Regarde, si tu veux. Mais ici rien n'est gratuit : l'or des morts paie aussi bien que le tien.",
		]})
	# La médecin : grande et mince, en tenue sombre à capuche comme une médecin de la peste
	# (sans masque : il n'existe pas dans nos packs) ; elle goûte ses mélanges.
	_survivant({"nom": "La médecin", "tenue": "Female_Ranger", "femme": true, "teinte": Color(0.2, 0.18, 0.18), "activite": "etal",
		"coiffures": [], "cheveux": Color(0.12, 0.1, 0.1),
		"taille": 1.03, "corpulence": 0.9, "gestes": ["Interact", "ual2/Consume"],
		"ou": _poste_medecin, "regard": Chemin.VILLAGE,
		"boutique": "medecin", "titre_boutique": "Potions et remèdes",
		"repliques": [
			"Des potions pour les blessures, des herbes contre la fièvre… et contre la peur, rien.",
			"Les herbes coûtent cher à cueillir, quand la forêt mord. Voilà ce que j'ai.",
		]})
	# Bran : adossé au poteau de l'entrée, bras croisés, il regarde la route.
	var bran := _poteau_entree - Chemin.HAUT_ECRAN * 0.45
	_survivant({"nom": "Bran", "tenue": "Male_Ranger", "teinte": Color(0.42, 0.48, 0.45), "activite": "bras_croises",
		"taille": 1.04, "gestes": ["ual2/Idle_No"],
		"ou": bran, "regard": bran - Chemin.HAUT_ECRAN * 5.0,
		"repliques": [
			"Halte. … Tu as la peau froide, mais tu respires. Ça me suffit.",
			"Je garde l'entrée. Les os remontent de la terre, et ici la nuit ne finit plus.",
			"Va te réchauffer au feu. Le vieux Hugo te fera une place.",
		]})
	# Hugo : le vieux conteur, petit et voûté, assis au feu ; il parle tout seul.
	_survivant({"nom": "Hugo", "tenue": "Male_Peasant", "teinte": Color(0.5, 0.42, 0.36), "activite": "assis",
		"coiffures": ["Hair_Buzzed", "Hair_Beard"], "cheveux": Color(0.66, 0.64, 0.62),
		"taille": 0.94, "corpulence": 1.05, "gestes": ["Sitting_Talking"],
		"ou": Chemin.bruneval(-2.8, -2.9), "regard": Chemin.VILLAGE,
		"repliques": [
			"Assieds-toi, l'ami. Le feu est la dernière chose qui ne nous ment pas.",
			"Tu ne te souviens de rien ? Alors tu es comme nous : on a tous oublié à quoi ressemblait le jour.",
			"On dit qu'un dieu nous a tourné le dos. Moi, je crois qu'il nous a regardés trop longtemps.",
		]})
	# Élise : la plus jeune, toujours pressée, elle porte l'eau du puits à la médecin.
	_survivant({"nom": "Élise", "tenue": "Female_Peasant", "femme": true, "teinte": Color(0.42, 0.46, 0.55), "activite": "porte_eau",
		"coiffures": ["Hair_Buns"], "cheveux": Color(0.35, 0.24, 0.16), "taille": 0.94,
		"ou": Chemin.bruneval(-2.7, 3.3), "aller_vers": Chemin.bruneval(5.8, 4.4), "regard": Chemin.bruneval(5.8, 4.4),
		"repliques": [
			"Pardon, je n'ai pas le temps… Il faut de l'eau pour la médecin.",
			"L'eau du puits a un goût de fer depuis trois jours. Personne ne veut savoir pourquoi.",
		]})
	# Osric : le marchand bavard et bien nourri, chauve et barbu, devant son étal.
	_survivant({"nom": "Osric", "tenue": "Male_Peasant", "teinte": Color(0.6, 0.48, 0.3), "activite": "etal",
		"coiffures": ["Hair_Beard"], "cheveux": Color(0.3, 0.2, 0.14),
		"taille": 0.98, "corpulence": 1.08, "ventre": 1.5, "gestes": ["Idle_Talking", "ual2/Yes", "Interact"],
		"ou": _poste_osric, "regard": _regard_osric,
		"repliques": [
			"Des pommes, des carottes, de la corde. Le reste, je ne le vends plus.",
			"Les pièces se font rares, l'ami. Les morts en portent encore sur eux, va savoir pourquoi.",
			"Si tu sors du hameau, garde ton épée près de toi. Les morts ne marchandent pas.",
		]})
	# Maren : la rôdeuse silencieuse, bras croisés à droite de la maison du chef.
	_survivant({"nom": "Maren", "tenue": "Female_Ranger", "femme": true, "teinte": Color(0.4, 0.36, 0.46), "activite": "bras_croises",
		"taille": 1.0, "corpulence": 0.95, "gestes": ["ual2/Idle_No"],
		"ou": Chemin.bruneval(3.8, 7.6), "regard": Chemin.VILLAGE,
		"repliques": [
			"… Tu viens de la forêt. Tu as vu l'autel rouge, n'est-ce pas ?",
			"J'ai laissé une lettre dans la cabane, sur la route. Pour Aldric.",
			"Il est parti chercher sa fille avant que les routes se ferment. Il n'est jamais revenu.",
			"Ce dieu n'a pas fini. Tant qu'il restera quelqu'un à protéger, il restera un dieu à abattre.",
		]})
	# Deux villageois qui flânent sur la place.
	_survivant({"nom": "Jeanne", "tenue": "Female_Peasant", "femme": true, "teinte": Color(0.56, 0.42, 0.4), "activite": "balade",
		"coiffures": ["Hair_SimpleParted"], "cheveux": Color(0.42, 0.2, 0.12), "taille": 0.97,
		"points": balade, "gestes": ["ual2/Yes"],
		"ou": balade[2], "regard": Chemin.VILLAGE,
		"repliques": [
			"Je fais le tour de la place. Si je m'arrête, je pense.",
			"Mon mari est parti couper du bois avant la nuit. La nuit qui ne finit plus.",
		]})
	_survivant({"nom": "Thibault", "tenue": "Male_Peasant", "teinte": Color(0.4, 0.46, 0.36), "activite": "balade",
		"coiffures": ["Hair_Buzzed"], "cheveux": Color(0.3, 0.22, 0.15), "taille": 1.0, "corpulence": 0.95,
		"points": balade, "gestes": ["Idle_Talking"],
		"ou": balade[6], "regard": Chemin.VILLAGE,
		"repliques": [
			"T'as une épée ? Moi j'ai qu'un bâton. Bran dit que ça suffit pas.",
			"Un jour je partirai avec toi, au-delà de la porte du nord.",
		]})


func _survivant(d: Dictionary) -> void:
	var s := Node3D.new()
	s.set_script(load("res://scripts/survivant.gd"))
	s.name = d["nom"]
	s.nom = d["nom"]
	s.tenue = d["tenue"]
	s.femme = d.get("femme", false)
	s.teinte = d["teinte"]
	s.activite = d["activite"]
	s.boutique = d.get("boutique", "")
	s.titre_boutique = d.get("titre_boutique", "")
	s.quete = d.get("quete", false)
	s.taille = d.get("taille", 1.0)
	s.corpulence = d.get("corpulence", 1.0)
	s.ventre = d.get("ventre", 1.0)
	s.point_de_frappe = d.get("frappe", Vector3.ZERO)
	var gestes: Array[String] = []
	gestes.assign(d.get("gestes", []))
	s.gestes = gestes
	var points: Array[Vector3] = []
	points.assign(d.get("points", []))
	s.points_de_balade = points
	var coiffures: Array[String] = []
	coiffures.assign(d.get("coiffures", []))
	s.coiffures = coiffures
	s.couleur_cheveux = d.get("cheveux", Color(0.25, 0.22, 0.2))
	var repliques: Array[String] = []
	repliques.assign(d["repliques"])
	s.repliques = repliques
	s.position = d["ou"]
	s.aller_vers = d.get("aller_vers", d["ou"])
	add_child(s)
	var vers: Vector3 = d["regard"] - s.position
	s.get_child(0).rotation.y = atan2(vers.x, vers.z)


# --- Outils -------------------------------------------------------------------------

## L'angle (autour de la verticale) pour que le +Z d'un objet regarde une cible.
func _vers(depuis: Vector3, cible: Vector3) -> float:
	var d := cible - depuis
	return atan2(d.x, d.z)


func _poutre(a: Vector3, b: Vector3, rayon: float, mat: Material) -> MeshInstance3D:
	var forme := CylinderMesh.new()
	forme.top_radius = rayon
	forme.bottom_radius = rayon * 1.08
	forme.height = a.distance_to(b)
	forme.radial_segments = 8
	var poutre := MeshInstance3D.new()
	poutre.mesh = forme
	poutre.material_override = mat
	var axe := (b - a).normalized()
	var x := axe.cross(Vector3.FORWARD if absf(axe.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	poutre.basis = Basis(x, axe, x.cross(axe))
	poutre.position = (a + b) / 2.0
	return poutre


func _obstacle(forme: Shape3D, transfo: Transform3D) -> void:
	var zone := CollisionShape3D.new()
	zone.shape = forme
	var corps := StaticBody3D.new()
	corps.transform = transfo
	corps.add_child(zone)
	add_child(corps)


func _obstacle_rond(pos: Vector3, rayon: float) -> void:
	var forme := CylinderShape3D.new()
	forme.radius = rayon
	forme.height = 2.0
	_obstacle(forme, Transform3D(Basis(), pos + Vector3(0, 1.0, 0)))
