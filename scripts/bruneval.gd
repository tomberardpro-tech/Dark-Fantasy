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
## L'icône de quête au-dessus de la porte du chef, qui flotte doucement.
var _quete: Label3D
var _hauteur_quete := 0.0
## Où se tiennent le forgeron et le médecin, derrière leur étal.
var _poste_forgeron := Vector3.ZERO
var _poste_medecin := Vector3.ZERO


func _ready() -> void:
	_rng.seed = 1848
	_creer_place()
	# Comme sur la maquette de Tom : de petites maisons serrées autour de la place, toutes
	# tournées vers le feu, le forgeron et la médecin devant leur stand.
	# [x, y, largeur, longueur de façade, étages, briques, nom,
	# rotation vers la place (0 = face à la caméra, 1 = face au feu)]
	_maison(0.0, 10.0, 4, 4, 2, false, "Maison du chef", 1.0)
	_maison(-11.0, 2.5, 4, 4, 1, true, "Forge", 1.0)
	_maison(11.0, 3.0, 4, 4, 1, false, "Médecin", 1.0)
	_maison(-9.5, -8.5, 4, 4, 1, false, "Abri", 1.0)
	_maison(9.5, -8.5, 4, 4, 1, false, "Abri de l'est", 1.0)
	_creer_forge(-11.0, 2.5)
	_creer_feu()
	_creer_puits(5.8, 2.2)
	_creer_etal(-6.0, -5.2)
	_creer_etal_medecin(11.0, 3.0)
	_chemin_de_sortie()
	_creer_rempart()
	_creer_survivants()


## La lueur de la forge vacille.
func _process(delta: float) -> void:
	_temps += delta
	for i in _feux.size():
		_feux[i].light_energy = 1.4 + sin(_temps * 11.0 + i) * 0.2 + sin(_temps * 6.3) * 0.15
	if _quete:
		_quete.position.y = _hauteur_quete + sin(_temps * 2.2) * 0.12


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
	# Une lanterne au-dessus de la porte du chef, et l'icône de quête au-dessus de la porte.
	if nom == "Maison du chef":
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
		# L'icône de quête : un « ! » doré qui flotte au-dessus de la porte (le chef est
		# à l'intérieur ; on pourra entrer plus tard).
		_quete = Label3D.new()
		_quete.text = "!"
		_quete.font = load("res://assets/polices/Cinzel.ttf")
		_quete.font_size = 96
		_quete.pixel_size = 0.01
		_quete.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_quete.modulate = Color("f2c46b")
		_quete.outline_modulate = Color("07091a")
		_quete.outline_size = 14
		_quete.position = Vector3(demi_l + 0.4, 3.6, demi_p - 1.0 - porte * 2.0)
		maison.add_child(_quete)
		_hauteur_quete = _quete.position.y
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

## Le poste du forgeron, devant la forge et tourné vers la place : l'établi (derrière
## lequel il se tient), l'enclume et la pierre à aiguiser de chaque côté, le râtelier
## d'armes et le foyer rougeoyant. C'est là qu'on lui achètera armes et armures.
func _creer_forge(x: float, y: float) -> void:
	var maison := Chemin.bruneval(x, y)
	var vers_place := (Chemin.VILLAGE - maison).normalized()
	var cote := Vector3(-vers_place.z, 0, vers_place.x)
	var poste := maison + vers_place * 3.6
	var face := _vers(poste, Chemin.VILLAGE)
	var etabli := Modeles.creer("Workbench")
	etabli.position = poste
	etabli.rotation.y = face
	add_child(etabli)
	var forme := BoxShape3D.new()
	forme.size = Vector3(2.0, 0.9, 1.0)
	_obstacle(forme, Transform3D(Basis(Vector3.UP, face), poste + Vector3(0, 0.45, 0)))
	_poste_forgeron = poste - vers_place * 1.0
	var enclume := Modeles.creer("Anvil")
	enclume.position = poste + cote * 1.7 + vers_place * 0.2
	enclume.rotation.y = face + 0.3
	add_child(enclume)
	_obstacle_rond(enclume.position, 0.45)
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
	var face := _vers(poste, Chemin.VILLAGE)
	var tourne := Basis(Vector3.UP, face)
	var etal := Modeles.creer("Stall_Empty")
	etal.position = poste
	etal.rotation.y = face
	add_child(etal)
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.9, 1.0, 1.0)
	_obstacle(forme, Transform3D(tourne, poste + Vector3(0, 0.5, 0)))
	_poste_medecin = poste - vers_place * 0.95
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
	chaudron.position = poste + cote * 1.7 - vers_place * 0.3
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
	var courbe := Curve3D.new()
	courbe.bake_interval = 1.0
	var points := [Chemin.bruneval(4.5, 5.5), Chemin.bruneval(7.5, 11.0), Chemin.bruneval(9.5, 17.0),
		Chemin.bruneval(10.5, 23.0), Chemin.bruneval(11.0, 29.0)]
	for i in points.size():
		var avant: Vector3 = points[max(i - 1, 0)]
		var apres: Vector3 = points[min(i + 1, points.size() - 1)]
		courbe.add_point(points[i], -(apres - avant) * 0.25, (apres - avant) * 0.25)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/chemin.gdshader")
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cuits := courbe.get_baked_points()
	var travers := [-1.9, -1.2, -0.6, 0.0, 0.6, 1.2, 1.9]
	var parcouru := 0.0
	for i in cuits.size():
		if i > 0:
			parcouru += cuits[i].distance_to(cuits[i - 1])
		var tangente := (cuits[min(i + 1, cuits.size() - 1)] - cuits[max(i - 1, 0)]).normalized()
		var cote := Vector3(-tangente.z, 0.0, tangente.x)
		var demi := Chemin.demi_largeur(parcouru + 40.0) * 0.85
		# Le chemin naît de la place en dégradé et se perd dans la forêt au bout.
		var apparition := smoothstep(0.0, 3.0, parcouru) * (1.0 - smoothstep(cuits.size() - 7.0, cuits.size() - 1.0, float(i)))
		for u in travers:
			outil.set_color(Color(0.2, 0, 0, apparition))
			outil.set_normal(Vector3.UP)
			outil.set_uv(Vector2(u, parcouru))
			outil.add_vertex(cuits[i] + cote * u * demi + Vector3(0, 0.03, 0))
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


## Le rempart (demande de Tom) : des pieux de bois taillés en pointe, serrés tout autour de
## la clairière, tenus par deux traverses côté village. Il s'ouvre là où arrive le chemin ;
## sur le chemin de sortie, une porte de planches reste fermée (la Zone 1 n'existe pas
## encore). On ne le traverse pas.
func _creer_rempart() -> void:
	var ecorce := StandardMaterial3D.new()
	ecorce.albedo_texture = load("res://assets/nature/Bark_NormalTree.png")
	ecorce.albedo_color = Color(0.62, 0.52, 0.45)
	ecorce.roughness = 1.0
	# Un pieu : un tronc fin et sa pointe, en un seul maillage, répété avec un MultiMesh.
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
		for v in [[pa, 0.0], [pa + h, 2.3], [pb + h, 2.3], [pa, 0.0], [pb + h, 2.3], [pb, 0.0], [pa + h, 2.3], [pointe, 2.75], [pb + h, 2.3]]:
			var p: Vector3 = v[0]
			outil.set_uv(Vector2(float(i) / cotes, v[1] * 0.5))
			outil.add_vertex(p)
	outil.generate_normals()
	var pieu := outil.commit()
	pieu.surface_set_material(0, ecorce)
	# Les places des pieux, tous les 0,36 m le long du bord de la clairière.
	var sortie := [Chemin.bruneval(4.5, 5.5), Chemin.bruneval(7.5, 11.0), Chemin.bruneval(9.5, 17.0)]
	var places: Array[Transform3D] = []
	var porte := Vector3.INF
	var fin_porte := Vector3.INF
	var pas := 400
	var avant := Chemin.bord_bruneval(0.0, 0.3)
	var depuis := 0.0
	var debut_mur := Vector3.INF
	for i in pas + 1:
		var p := Chemin.bord_bruneval(TAU * i / pas, 0.3)
		depuis += p.distance_to(avant)
		var ouvert := Chemin.distance_au_chemin(p) < 2.6
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
			var penche := Basis(Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized(), _rng.randf_range(0.0, 0.05))
			var taille := Vector3(1.0, _rng.randf_range(0.85, 1.12), 1.0)
			places.append(Transform3D(penche * Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(taille), p))
		avant = p
	if debut_mur != Vector3.INF:
		_mur(debut_mur, avant)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = pieu
	multi.instance_count = places.size()
	for i in places.size():
		multi.set_instance_transform(i, places[i])
	var rempart := MultiMeshInstance3D.new()
	rempart.name = "Rempart"
	rempart.multimesh = multi
	rempart.set_meta("pieux", places)
	add_child(rempart)
	# Deux traverses côté village, par tronçons, pour tenir les pieux.
	var bois := Modeles.materiau_de("Floor_WoodDark")
	for i in range(0, places.size() - 1, 6):
		var a := places[i].origin
		var b := places[mini(i + 6, places.size() - 1)].origin
		if a.distance_to(b) > 3.0:
			continue
		var dedans := (Chemin.VILLAGE - (a + b) / 2.0).normalized() * 0.22
		for hauteur in [0.7, 1.8]:
			add_child(_poutre(a + dedans + Vector3.UP * hauteur, b + dedans + Vector3.UP * hauteur, 0.06, bois))
	# La porte fermée sur le chemin de sortie : des planches entre deux gros poteaux.
	if porte != Vector3.INF:
		var centre := (porte + fin_porte) / 2.0
		var travers := (fin_porte - porte).normalized()
		var demi := porte.distance_to(fin_porte) / 2.0 + 0.2
		var gauche := centre - travers * demi
		var droite := centre + travers * demi
		for poteau in [gauche, droite]:
			add_child(_poutre(poteau, poteau + Vector3.UP * 3.2, 0.24, ecorce))
		var planches := int(demi / 0.38) * 2 + 1
		for k in planches:
			var x := lerpf(-demi + 0.2, demi - 0.2, k / float(planches - 1))
			add_child(_poutre(centre + travers * x, centre + travers * x + Vector3.UP * _rng.randf_range(2.35, 2.55), 0.19, ecorce))
		for hauteur in [0.6, 1.9]:
			add_child(_poutre(gauche + Vector3.UP * hauteur, droite + Vector3.UP * hauteur, 0.08, bois))
		_mur(gauche, droite)


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
	for o in [["FarmCrate_Apple", Vector3(1.4, 0, 0.5)], ["FarmCrate_Carrot", Vector3(-1.5, 0, 0.3)], ["Barrel_Apples", Vector3(1.2, 0, -0.7)]]:
		var objet := Modeles.creer(o[0])
		objet.position = pos + Basis(Vector3.UP, etal.rotation.y) * o[1]
		objet.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(objet)


# --- Les survivants -------------------------------------------------------------------

## Les cinq survivants (étape 10), leurs tenues, leur activité et leurs répliques
## (proposées par Claude, à valider par Tom : on peut les changer ici).
func _creer_survivants() -> void:
	# Les deux marchands, derrière leur étal, face à la place. Après la première
	# conversation, E ouvre directement leur boutique (voir boutiques.gd).
	_survivant({"nom": "Le forgeron", "tenue": "Male_Peasant", "teinte": Color(0.36, 0.32, 0.3), "activite": "etal",
		"coiffures": ["Hair_Buzzed", "Hair_Beard"], "cheveux": Color(0.16, 0.12, 0.1),
		"ou": _poste_forgeron, "regard": Chemin.VILLAGE,
		"boutique": "forgeron", "titre_boutique": "Armes et armures",
		"repliques": [
			"Des lames, des armures… Le métal ne manque pas. C'est le temps qui manque.",
			"Regarde, si tu veux. Mais ici rien n'est gratuit : l'or des morts paie aussi bien que le tien.",
		]})
	_survivant({"nom": "La médecin", "tenue": "Female_Peasant", "femme": true, "teinte": Color(0.46, 0.5, 0.44), "activite": "etal",
		"coiffures": ["Hair_SimpleParted"], "cheveux": Color(0.12, 0.1, 0.1),
		"ou": _poste_medecin, "regard": Chemin.VILLAGE,
		"boutique": "medecin", "titre_boutique": "Potions et remèdes",
		"repliques": [
			"Des potions pour les blessures, des herbes contre la fièvre… et contre la peur, rien.",
			"Les herbes coûtent cher à cueillir, quand la forêt mord. Voilà ce que j'ai.",
		]})
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
		"ou": Chemin.bruneval(7.0, 0.8), "aller_vers": Chemin.bruneval(8.4, -6.4), "regard": Chemin.bruneval(8.4, -6.4),
		"repliques": [
			"Pardon, je n'ai pas le temps… Il faut de l'eau pour le médecin.",
			"L'eau du puits a un goût de fer depuis trois jours. Personne ne veut savoir pourquoi.",
		]})
	_survivant({"nom": "Osric", "tenue": "Male_Peasant", "teinte": Color(0.6, 0.48, 0.3), "activite": "etal",
		"coiffures": ["Hair_SimpleParted"], "cheveux": Color(0.2, 0.15, 0.12),
		"ou": Chemin.bruneval(-6.5, -4.1), "regard": Chemin.bruneval(-3.6, -9.5),
		"repliques": [
			"Des pommes, des carottes, de la corde. Le reste, je ne le vends plus.",
			"Les pièces se font rares, l'ami. Les morts en portent encore sur eux, va savoir pourquoi.",
			"Si tu sors du hameau, garde ton épée près de toi. Les morts ne marchandent pas.",
		]})
	_survivant({"nom": "Maren", "tenue": "Female_Ranger", "femme": true, "teinte": Color(0.4, 0.36, 0.46), "activite": "bras_croises",
		"ou": Chemin.bruneval(-3.8, 7.6), "regard": Chemin.VILLAGE,
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
	s.boutique = d.get("boutique", "")
	s.titre_boutique = d.get("titre_boutique", "")
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
