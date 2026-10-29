extends Node3D
## Le hameau de Bruneval, d'après la maquette « naturelle » validée par Tom : des maisons
## posées sans symétrie dans une clairière, chacune tournée vers la place (avec un petit
## écart), une place de terre boueuse avec le feu et le puits, l'étal d'Osric, la forge et
## son tas de bois, un potager, une charrette, des rochers. Pas de palissade : la forêt
## l'entoure (voir foret.json). Pièces du Medieval Village MegaKit et du Fantasy Props
## MegaKit (Quaternius).
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
	# [x, y, largeur, profondeur, étages, murs en briques, nom]
	_maison(-4.0, 13.5, 6, 10, 2, false, "Auberge")
	_maison(-17.5, 0.5, 4, 6, 1, true, "Forge")
	_maison(15.5, 7.0, 6, 6, 1, false, "Médecin")
	_maison(11.0, -12.0, 4, 4, 1, false, "Abri")
	_maison(18.0, 16.5, 4, 4, 1, false, "Abri du fond")
	_creer_forge(-17.5, 0.5)
	_creer_feu()
	_creer_puits(6.2, 2.6)
	_creer_etal(-6.0, -9.5)
	_creer_tas_de_bois(-13.4, -4.2)
	_creer_potager(22.2, -1.5)
	_creer_charrette(-11.0, -13.0)
	for r in [[-20.0, -9.0, 1.2], [9.0, -18.0, 0.8], [22.0, 4.0, 1.0], [-9.0, 18.0, 0.9], [3.5, -6.0, 0.5]]:
		var rocher := Modeles.creer("Rock_Medium_" + str(_rng.randi_range(1, 3)), Modeles.NATURE, TEINTE_PIERRE)
		rocher.position = Chemin.bruneval(r[0], r[1]) - Vector3(0, 0.1, 0)
		rocher.rotation.y = _rng.randf_range(0.0, TAU)
		rocher.scale = Vector3.ONE * r[2] * 0.32
		add_child(rocher)
		_obstacle_rond(rocher.position, r[2] * 0.45)


## La lueur de la forge vacille.
func _process(delta: float) -> void:
	_temps += delta
	for i in _feux.size():
		_feux[i].light_energy = 1.4 + sin(_temps * 11.0 + i) * 0.2 + sin(_temps * 6.3) * 0.15


# --- La place -------------------------------------------------------------------

## La place : une tache de terre boueuse aux bords irréguliers (même matière que le chemin,
## avec ses flaques), autour du feu.
func _creer_place() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/chemin.gdshader")
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tours := 40
	var centre := Chemin.bruneval(1.0, 1.0) + Vector3(0, 0.025, 0)
	# Pour chaque tranche : un triangle du centre au bord, puis le fondu vers l'extérieur.
	for i in tours:
		var points := []
		for k in [0, 1]:
			var t: float = TAU * (i + k) / tours
			var r := 1.0 + 0.22 * sin(t * 2.0 + 0.5) + 0.12 * sin(t * 5.0)
			points.append(Chemin.bruneval(1.0 + 8.5 * r * sin(t), 1.0 + 6.5 * r * cos(t)) + Vector3(0, 0.025, 0))
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
	feu.position = Chemin.bruneval(0.5, -0.6)
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
func _maison(x: float, y: float, largeur: int, profondeur: int, etages: int, briques: bool, nom: String) -> void:
	var maison := Node3D.new()
	maison.name = nom
	maison.position = Chemin.bruneval(x, y)
	maison.rotation.y = _vers(maison.position, Chemin.bruneval(1.0, 0.5)) + _rng.randf_range(-0.18, 0.18)
	add_child(maison)
	var prefixe := "Wall_UnevenBrick_" if briques else "Wall_Plaster_"
	var murs_pleins := ["Wall_UnevenBrick_Straight"] if briques else ["Wall_Plaster_Straight", "Wall_Plaster_WoodGrid"]
	var demi_l := largeur / 2.0
	var demi_p := profondeur / 2.0
	var porte := _rng.randi_range(0, largeur / 2 - 1)
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
				if cote == 0 and etage == 0 and i == porte:
					modele = prefixe + "Door_Flat"
				elif cote != 2 and _rng.randf() < 0.55:
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
		cheminee.position = Vector3(demi_l - 0.9, haut + 0.4, -demi_p + 1.2)
		maison.add_child(cheminee)
	# Une lanterne au-dessus de la porte de l'auberge.
	if nom == "Auberge":
		var lanterne := Modeles.creer("Lantern_Wall")
		lanterne.position = Vector3(-demi_l + 1.0 + porte * 2.0 + 1.0, 2.6, demi_p + 0.1)
		maison.add_child(lanterne)
		var lumiere := OmniLight3D.new()
		lumiere.light_color = COULEUR_FENETRE
		lumiere.light_energy = 1.0
		lumiere.omni_range = 6.0
		lumiere.position = lanterne.position + Vector3(0, -0.2, 0.6)
		maison.add_child(lumiere)
	# Un peu de lierre, des tonneaux ou des caisses contre les murs (au hasard).
	if _rng.randf() < 0.6:
		var lierre := Modeles.creer(["Prop_Vine1", "Prop_Vine4"][_rng.randi_range(0, 1)], Modeles.OBJETS, Color(0.42, 0.5, 0.52))
		lierre.position = Vector3(_rng.randf_range(-demi_l + 0.8, demi_l - 0.8), haut - 0.2, -demi_p - 0.2)
		maison.add_child(lierre)
	for k in _rng.randi_range(1, 3):
		var objet := Modeles.creer(["Barrel", "Crate_Wooden", "Prop_Crate"][_rng.randi_range(0, 2)])
		var cote := -1.0 if _rng.randf() < 0.5 else 1.0
		objet.position = Vector3(cote * (demi_l + 0.5), 0, _rng.randf_range(-demi_p + 0.8, demi_p - 0.8))
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
	var vers_place := (Chemin.bruneval(1.0, 0.5) - devant).normalized()
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


## Un tas de bûches à côté de la forge.
func _creer_tas_de_bois(x: float, y: float) -> void:
	var pos := Chemin.bruneval(x, y)
	var ecorce := StandardMaterial3D.new()
	ecorce.albedo_texture = load("res://assets/nature/Bark_NormalTree.png")
	ecorce.albedo_color = Color(0.5, 0.42, 0.38)
	ecorce.roughness = 1.0
	var sens := Vector3(1, 0, 0).rotated(Vector3.UP, _rng.randf_range(0.0, PI))
	var cote := sens.cross(Vector3.UP)
	var rangees := [[0.0, 4], [0.24, 3], [0.46, 2]]
	for r in rangees:
		for i in r[1]:
			var decal: float = (i - (r[1] - 1) / 2.0) * 0.25
			var centre: Vector3 = pos + cote * decal + Vector3(0, 0.12 + r[0], 0) + sens * _rng.randf_range(-0.1, 0.1)
			add_child(_poutre(centre - sens * 0.6, centre + sens * 0.6, 0.11, ecorce))
	_obstacle_rond(pos, 0.7)


## Un petit potager clôturé avec des rangs de légumes.
func _creer_potager(x: float, y: float) -> void:
	var centre := Chemin.bruneval(x, y)
	var angle := _rng.randf_range(-0.3, 0.3)
	var tourne := Basis(Vector3.UP, atan2(Chemin.HAUT_ECRAN.x, Chemin.HAUT_ECRAN.z) + angle)
	var terre := MeshInstance3D.new()
	var plan := BoxMesh.new()
	plan.size = Vector3(4.6, 0.04, 3.0)
	terre.mesh = plan
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("241c15")
	mat.roughness = 1.0
	terre.material_override = mat
	terre.basis = tourne
	terre.position = centre + Vector3(0, 0.02, 0)
	add_child(terre)
	for rang in 4:
		for k in 6:
			var pousse := Modeles.creer("Grass_Common_Short", Modeles.NATURE, Color(0.4, 0.55, 0.38))
			pousse.position = centre + tourne * Vector3(-1.9 + k * 0.75, 0.04, -1.1 + rang * 0.72)
			pousse.scale = Vector3.ONE * _rng.randf_range(0.35, 0.5)
			add_child(pousse)
	for i in 3:
		var barriere := Modeles.creer("Prop_WoodenFence_Single")
		barriere.basis = tourne
		barriere.position = centre + tourne * Vector3(-1.6 + i * 1.6, 0, -1.7)
		add_child(barriere)
	var caisse := Modeles.creer("FarmCrate_Carrot")
	caisse.position = centre + tourne * Vector3(2.8, 0, 0.6)
	add_child(caisse)
	var forme := BoxShape3D.new()
	forme.size = Vector3(4.6, 1.0, 3.2)
	_obstacle(forme, Transform3D(tourne, centre + Vector3(0, 0.5, 0)))


func _creer_charrette(x: float, y: float) -> void:
	var pos := Chemin.bruneval(x, y)
	var charrette := Modeles.creer("Prop_Wagon")
	charrette.position = pos
	charrette.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(charrette)
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.8, 1.6, 4.0)
	_obstacle(forme, Transform3D(Basis(Vector3.UP, charrette.rotation.y), pos + charrette.basis * Vector3(0, 0.8, -1.15)))
	var tonneau := Modeles.creer("Barrel_Apples")
	tonneau.position = pos + charrette.basis * Vector3(1.4, 0, 0.6)
	add_child(tonneau)


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
