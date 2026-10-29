extends Node3D
## Le hameau de Bruneval, d'après la maquette choisie par Tom : les maisons en arc autour
## d'une place de terre boueuse (feu de camp, banc, puits), façades éclairées vers la caméra,
## légèrement tournées vers la place ; l'auberge à étage au fond, la forge en briques à
## gauche, le médecin à droite, deux abris devant, l'étal d'Osric. Pas de palissade : une
## ceinture de sapins entoure la clairière (voir foret.json). Pièces du Medieval Village
## MegaKit et du Fantasy Props MegaKit (Quaternius).
##
## Les positions sont celles de la maquette (x vers la droite de l'écran, y vers le haut),
## converties par Chemin.bruneval().

const TEINTE_PIERRE := Color(0.55, 0.58, 0.68)
const COULEUR_FENETRE := Color("f2b766")

var _rng := RandomNumberGenerator.new()
var _feux: Array[OmniLight3D] = []
var _temps := 0.0


func _ready() -> void:
	_rng.seed = 1848
	_creer_place()
	# Comme sur la maquette choisie par Tom : les maisons en arc autour de la place, façades
	# éclairées vers la caméra. [x, y, largeur, longueur de façade, étages, briques, nom,
	# rotation vers la place (0 = face à la caméra, 1 = face au feu)]
	_maison(0.0, 15.2, 6, 10, 2, false, "Auberge", 0.0)
	_maison(-19.3, 3.1, 4, 8, 1, true, "Forge", 0.3)
	_maison(20.2, 3.8, 6, 8, 1, false, "Médecin", 0.3)
	_maison(-17.1, -8.7, 4, 6, 1, false, "Abri", 0.25)
	_maison(17.1, -9.1, 4, 6, 1, false, "Abri de l'est", 0.25)
	_creer_forge(-19.3, 3.1)
	_creer_feu()
	_creer_puits(5.6, 3.3)
	_creer_etal(-7.4, -5.7)
	_creer_survivants()


## La lueur de la forge vacille.
func _process(delta: float) -> void:
	_temps += delta
	for i in _feux.size():
		_feux[i].light_energy = 1.4 + sin(_temps * 11.0 + i) * 0.2 + sin(_temps * 6.3) * 0.15


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
	# Le banc du vieux Hugo, tourné vers le feu.
	var banc := Modeles.creer("Bench")
	banc.position = Chemin.bruneval(-2.8, -2.9)
	banc.rotation.y = _vers(banc.position, feu.position) + 0.1
	add_child(banc)
	var forme := BoxShape3D.new()
	forme.size = Vector3(2.8, 0.5, 0.55)
	_obstacle(forme, Transform3D(Basis(Vector3.UP, banc.rotation.y), banc.position + Vector3(0, 0.25, 0)))


# --- Les maisons ------------------------------------------------------------------

## Une maison de « largeur » × « profondeur » mètres (multiples de 2), d'un ou deux étages,
## en plâtre ou en briques. Sa façade (avec la porte, sous le pignon) regarde la place.
func _maison(x: float, y: float, largeur: int, profondeur: int, etages: int, briques: bool, nom: String, vers_place := 0.0) -> void:
	var maison := Node3D.new()
	maison.name = nom
	maison.position = Chemin.bruneval(x, y)
	# La façade (le long côté, en +X) regarde la caméra, un peu tournée vers la place
	# selon « vers_place » (0 = droit face à la caméra).
	var vers_camera := -Chemin.HAUT_ECRAN
	var vers_le_feu := (Chemin.VILLAGE - maison.position).normalized()
	var facade := vers_camera.lerp(vers_le_feu, vers_place).normalized()
	maison.rotation.y = atan2(-facade.z, facade.x)
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
	if nom == "Auberge" or nom == "Forge":
		var cheminee := Modeles.creer("Prop_Chimney")
		cheminee.position = Vector3(-demi_l + 0.9, haut + 0.4, demi_p - 1.2)
		maison.add_child(cheminee)
	# Une lanterne au-dessus de la porte de l'auberge.
	if nom == "Auberge":
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
	forme.size = Vector3(largeur, 3.0, profondeur)
	_obstacle(forme, maison.transform * Transform3D(Basis(), Vector3(0, 1.5, 0)))


## Une fenêtre éclairée de l'intérieur : le cadre, une lueur chaude derrière, parfois des
## volets ouverts, et une petite lumière qui éclaire le sol devant.
func _fenetre_allumee(maison: Node3D, pos: Vector3, angle: float) -> void:
	var tourne := Basis(Vector3.UP, angle)
	var cadre := Modeles.creer("Window_Wide_Flat1")
	cadre.position = pos
	cadre.rotation.y = angle
	maison.add_child(cadre)
	var lueur := MeshInstance3D.new()
	var plan := QuadMesh.new()
	plan.size = Vector2(1.3, 1.2)
	lueur.mesh = plan
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = COULEUR_FENETRE * (0.75 + _rng.randf() * 0.25)
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
	lumiere.light_energy = 0.55
	lumiere.omni_range = 3.5
	lumiere.position = pos + tourne * Vector3(0, 1.4, 0.9)
	maison.add_child(lumiere)


# --- La forge, le puits, l'étal… ----------------------------------------------------

func _creer_forge(x: float, y: float) -> void:
	var devant := Chemin.bruneval(x, y)
	var vers_place := (Chemin.VILLAGE - devant).normalized()
	var cote := Vector3(-vers_place.z, 0, vers_place.x)
	var enclume := Modeles.creer("Anvil")
	enclume.position = devant + vers_place * 4.3 + cote * 1.4
	enclume.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(enclume)
	_obstacle_rond(enclume.position, 0.45)
	var armes := Modeles.creer("WeaponStand")
	armes.position = devant + vers_place * 3.7 - cote * 2.0
	armes.rotation.y = _vers(armes.position, devant) + PI
	add_child(armes)
	# Le foyer : un bloc de briques dont le dessus rougeoie.
	var foyer := MeshInstance3D.new()
	var bloc := BoxMesh.new()
	bloc.size = Vector3(1.0, 0.8, 1.0)
	foyer.mesh = bloc
	foyer.material_override = Modeles.materiau_de("Wall_UnevenBrick_Straight")
	foyer.position = devant + vers_place * 3.9 + Vector3(0, 0.4, 0) - cote * 0.2
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
	for o in [["FarmCrate_Apple", Vector3(1.4, 0, 0.5)], ["FarmCrate_Carrot", Vector3(-1.5, 0, 0.3)], ["Barrel_Apples", Vector3(1.2, 0, -0.7)]]:
		var objet := Modeles.creer(o[0])
		objet.position = pos + Basis(Vector3.UP, etal.rotation.y) * o[1]
		objet.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(objet)


# --- Les survivants -------------------------------------------------------------------

## Les cinq survivants (étape 10), leurs tenues, leur activité et leurs répliques
## (proposées par Claude, à valider par Tom : on peut les changer ici).
func _creer_survivants() -> void:
	_survivant({"nom": "Bran", "tenue": "Male_Ranger", "teinte": Color(0.42, 0.48, 0.45), "activite": "garde",
		"ou": Chemin.bruneval(2.4, -19.0), "regard": Chemin.bruneval(2.4, -30.0),
		"repliques": [
			"Halte. … Tu as la peau froide, mais tu respires. Ça me suffit.",
			"Je garde l'entrée. Les os remontent de la terre, et ici la nuit ne finit plus.",
			"Va te réchauffer au feu. Le vieux Hugo te fera une place.",
		]})
	_survivant({"nom": "Hugo", "tenue": "Male_Peasant", "teinte": Color(0.5, 0.42, 0.36), "activite": "assis",
		"coiffures": ["Hair_Buzzed", "Hair_Beard"], "cheveux": Color(0.62, 0.6, 0.58),
		"ou": Chemin.bruneval(-2.8, -2.9), "regard": Chemin.VILLAGE,
		"repliques": [
			"Assieds-toi, l'ami. Le feu est la dernière chose qui ne nous ment pas.",
			"Tu ne te souviens de rien ? Alors tu es comme nous : on a tous oublié à quoi ressemblait le jour.",
			"On dit qu'un dieu nous a tourné le dos. Moi, je crois qu'il nous a regardés trop longtemps.",
		]})
	_survivant({"nom": "Élise", "tenue": "Female_Peasant", "femme": true, "teinte": Color(0.42, 0.46, 0.55), "activite": "porte_eau",
		"coiffures": ["Hair_Buns"], "cheveux": Color(0.35, 0.24, 0.16),
		"ou": Chemin.bruneval(6.8, 1.8), "aller_vers": Chemin.bruneval(15.0, -6.8), "regard": Chemin.bruneval(15.0, -6.8),
		"repliques": [
			"Pardon, je n'ai pas le temps… Il faut de l'eau pour le médecin.",
			"L'eau du puits a un goût de fer depuis trois jours. Personne ne veut savoir pourquoi.",
		]})
	_survivant({"nom": "Osric", "tenue": "Male_Peasant", "teinte": Color(0.6, 0.48, 0.3), "activite": "etal",
		"coiffures": ["Hair_SimpleParted"], "cheveux": Color(0.2, 0.15, 0.12),
		"ou": Chemin.bruneval(-7.9, -4.6), "regard": Chemin.bruneval(-5.0, -10.0),
		"repliques": [
			"Des pommes, des carottes, de la corde. Le reste, je ne le vends plus.",
			"L'or ne vaut plus rien, l'ami. Ramène-moi plutôt quelque chose qui brille encore.",
			"Si tu sors du hameau, garde ton épée près de toi. Les morts ne marchandent pas.",
		]})
	_survivant({"nom": "Maren", "tenue": "Female_Ranger", "femme": true, "teinte": Color(0.4, 0.36, 0.46), "activite": "bras_croises",
		"ou": Chemin.bruneval(3.6, 11.4), "regard": Chemin.VILLAGE,
		"repliques": [
			"… Tu viens de la forêt. Tu as vu l'autel rouge, n'est-ce pas ?",
			"J'ai laissé une lettre dans la cabane, sur la route. Pour Aldric.",
			"Il est parti chercher sa fille avant que les routes se ferment. Il n'est jamais revenu.",
			"Ce dieu n'a pas fini. Tant qu'il restera quelqu'un à protéger, il restera un dieu à abattre.",
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
