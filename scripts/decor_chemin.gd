extends Node3D
## Tout ce qu'on voit le long du chemin (le tracé est dans chemin.gd) :
## le sentier de terre, les lanternes, le ruisseau et ses berges, le pont, la ruine
## de briques, l'autel abandonné à la lueur rouge, la charrette renversée et les
## torches de l'entrée de Bruneval. Les objets viennent des packs Quaternius
## (Medieval Village MegaKit et Fantasy Props MegaKit).

## Écart entre deux lanternes (en mètres).
@export var ecart_lanternes := 14.0
## Longueur sur laquelle le sentier apparaît doucement en sortant de la clairière.
@export var fondu_depart := 4.0
## Les limites invisibles du parcours, de chaque côté du chemin (en mètres).
@export var distance_bordure := 12.0

const COULEUR_TERRE := Color("3a2f29")
const COULEUR_TERRE_MOUILLEE := Color("1f1813")
const COULEUR_LANTERNE := Color("f0ad55")
const COULEUR_MAUDITE := Color("b0303a")
## Rayon du cercle invisible autour de la clairière.
const RAYON_CLAIRIERE := 16.0
const GALETS := ["Pebble_Round_1", "Pebble_Round_2", "Pebble_Round_3", "Pebble_Round_4", "Pebble_Round_5"]
const TEINTE_PIERRE := Color(0.55, 0.58, 0.68)
const TEINTE_HERBE := Color(0.42, 0.5, 0.52)

var _lumiere_autel: OmniLight3D
var _bois: Material
var _temps := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 77
	_bois = Modeles.materiau_de("Floor_WoodDark")
	add_child(_sentier())
	add_child(_berges_mouillees())
	add_child(_eau())
	_bruit_de_l_eau()
	# Le vent dans les arbres, partout, très doux.
	Sons.boucle_partout("vent", -24.0)
	_creer_berges()
	_creer_cailloux()
	_creer_racines()
	_creer_bordures()
	_creer_pont()
	_creer_lanternes()
	_creer_ruine()
	_creer_autel()
	_creer_torches_entree()
	var charrette := Node3D.new()
	charrette.set_script(load("res://scripts/charrette.gd"))
	charrette.position = Chemin.CHARRETTE
	charrette.rotation.y = Chemin.ROTATION_CHARRETTE
	add_child(charrette)
	var abri := Node3D.new()
	abri.set_script(load("res://scripts/abri_ecrivain.gd"))
	add_child(abri)
	var hameau := Node3D.new()
	hameau.name = "Bruneval"
	hameau.set_script(load("res://scripts/bruneval.gd"))
	add_child(hameau)


## La lueur rouge de l'autel palpite lentement : la malédiction n'est pas loin.
func _process(delta: float) -> void:
	_temps += delta
	_lumiere_autel.light_energy = 1.2 + sin(_temps * 1.3) * 0.35


## Le sentier de terre battue (son aspect est dans shaders/chemin.gdshader). Le ruban
## déborde largement du sentier : c'est le shader qui dessine les bords irréguliers.
func _sentier() -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/chemin.gdshader")
	var points := Chemin.courbe_chemin.get_baked_points()
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Positions en travers, en demi-largeurs : le bord est vers ±1, on va jusqu'à ±1,9.
	var travers := [-1.9, -1.2, -0.6, 0.0, 0.6, 1.2, 1.9]
	var parcouru := 0.0
	for i in points.size():
		if i > 0:
			parcouru += points[i].distance_to(points[i - 1])
		var tangente := (points[min(i + 1, points.size() - 1)] - points[max(i - 1, 0)]).normalized()
		var cote := Vector3(-tangente.z, 0.0, tangente.x)
		# Au départ, le sentier est plus étroit et apparaît en dégradé.
		var demi := Chemin.demi_largeur(parcouru) * lerpf(0.55, 1.0, smoothstep(0.0, fondu_depart * 1.5, parcouru))
		var humidite := 1.0 - smoothstep(3.0, 9.0, Chemin.distance_au_ruisseau(points[i]))
		var apparition := smoothstep(0.0, fondu_depart, parcouru)
		for u in travers:
			outil.set_color(Color(humidite, 0, 0, apparition))
			outil.set_normal(Vector3.UP)
			outil.set_uv(Vector2(u, parcouru))
			outil.add_vertex(points[i] + cote * u * demi + Vector3(0, 0.03, 0))
	var n := travers.size()
	for i in points.size() - 1:
		for k in n - 1:
			var a := i * n + k
			var b := a + n
			outil.add_index(a)
			outil.add_index(a + 1)
			outil.add_index(b)
			outil.add_index(a + 1)
			outil.add_index(b + 1)
			outil.add_index(b)
	var bande := MeshInstance3D.new()
	bande.mesh = outil.commit()
	bande.material_override = mat
	bande.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return bande


## Quelques cailloux à moitié enfoncés au bord du sentier, de loin en loin (discret).
func _creer_cailloux() -> void:
	var courbe := Chemin.courbe_chemin
	var longueur := courbe.get_baked_length()
	var distance := 10.0
	while distance < longueur - 4.0:
		var p := courbe.sample_baked(distance)
		var tangente := (courbe.sample_baked(min(distance + 1.0, longueur)) - p).normalized()
		var cote := Vector3(-tangente.z, 0, tangente.x) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var demi := Chemin.demi_largeur(distance)
		if _rng.randf() < 0.45 and p.distance_to(Chemin.PONT) > 5.0:
			var galet := Modeles.creer(GALETS[_rng.randi_range(0, 4)], Modeles.NATURE, TEINTE_PIERRE)
			galet.position = p + cote * demi * _rng.randf_range(0.85, 1.25) - Vector3(0, 0.03, 0)
			galet.rotation.y = _rng.randf_range(0.0, TAU)
			galet.scale = Vector3(1.0, 0.7, 1.0) * _rng.randf_range(0.9, 1.6)
			add_child(galet)
			# Parfois un petit rocher un peu plus loin du bord.
			if _rng.randf() < 0.3:
				var rocher := Modeles.creer("Rock_Medium_" + str(_rng.randi_range(1, 3)), Modeles.NATURE, TEINTE_PIERRE)
				rocher.position = p + cote * (demi * 1.5 + _rng.randf_range(0.3, 0.7)) - Vector3(0, 0.08, 0)
				rocher.rotation.y = _rng.randf_range(0.0, TAU)
				rocher.scale = Vector3.ONE * _rng.randf_range(0.13, 0.2)
				add_child(rocher)
		distance += _rng.randf_range(7.0, 12.0)


## Les racines des arbres proches du sentier, qui rampent vers lui et s'enfoncent dans la
## terre. On lit la place des arbres dans la disposition figée de la forêt.
func _creer_racines() -> void:
	var liste: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://donnees/foret.json"))
	if not liste is Array:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("2b221c")
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	for e in liste:
		if e.has("obstacle") or not (e["modele"].begins_with("Pine") or e["modele"].begins_with("DeadTree") or e["modele"].begins_with("TwistedTree")):
			continue
		var tronc := Vector3(e["x"], 0.0, e["z"])
		var d := Chemin.distance_au_chemin(tronc)
		if d < 1.8 or d > 4.0 or _rng.randf() > 0.4:
			continue
		var vers := _vers_le_chemin(tronc)
		for k in _rng.randi_range(1, 2):
			var direction := vers.rotated(Vector3.UP, _rng.randf_range(-0.6, 0.6))
			var longueur := clampf(d - 1.0, 0.8, 2.2) * _rng.randf_range(0.7, 1.0)
			add_child(_racine(tronc + direction * 0.18, direction, longueur, mat))


## La direction (au sol) d'un point vers le milieu du sentier le plus proche.
func _vers_le_chemin(p: Vector3) -> Vector3:
	var courbe := Chemin.courbe_chemin
	var proche := courbe.sample_baked(courbe.get_closest_offset(p))
	var vers := proche - p
	vers.y = 0.0
	return vers.normalized()


## Une racine : un tube qui s'amincit, sort du pied de l'arbre, se bombe un peu au-dessus
## du sol puis s'y enfonce.
func _racine(depart: Vector3, direction: Vector3, longueur: float, mat: Material) -> MeshInstance3D:
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cote := Vector3(-direction.z, 0, direction.x)
	var tranches := 7
	var faces := 5
	var ondule := _rng.randf_range(-0.25, 0.25)
	for i in tranches + 1:
		var t := float(i) / tranches
		var centre := depart + direction * longueur * t + cote * sin(t * PI) * ondule
		centre.y = 0.13 * (1.0 - t) + sin(t * PI) * 0.05 - t * t * 0.08
		var rayon := lerpf(0.085, 0.02, t)
		for f in faces:
			var a := TAU * f / faces
			var normale := (cote * cos(a) + Vector3.UP * sin(a)).normalized()
			outil.set_normal(normale)
			outil.add_vertex(centre + normale * rayon)
	for i in tranches:
		for f in faces:
			var a := i * faces + f
			var b := i * faces + (f + 1) % faces
			outil.add_index(a)
			outil.add_index(b)
			outil.add_index(a + faces)
			outil.add_index(b)
			outil.add_index(b + faces)
			outil.add_index(a + faces)
	var racine := MeshInstance3D.new()
	racine.mesh = outil.commit()
	racine.material_override = mat
	return racine


## Une bande de terre brune plus sombre et humide de chaque côté de l'eau : la rivière
## se fond dans la terre au lieu d'être une bande bleue posée sur le sol.
func _berges_mouillees() -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = COULEUR_TERRE_MOUILLEE
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	return _ruban(Chemin.courbe_ruisseau, 1.9, 3.2, 0.035, mat, 0.0)


## L'eau du ruisseau : sombre, calme, avec de petites rides qui bougent et le reflet
## de la lune (voir shaders/eau.gdshader).
func _eau() -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/eau.gdshader")
	return _ruban(Chemin.courbe_ruisseau, 1.3, 1.8, 0.04, mat, 0.0)


## Le bruit du ruisseau : des sources sonores tous les 16 m le long de l'eau ; on
## l'entend de plus en plus fort en s'approchant.
func _bruit_de_l_eau() -> void:
	var courbe := Chemin.courbe_ruisseau
	var longueur := courbe.get_baked_length()
	var d := 8.0
	while d < longueur:
		var source := Node3D.new()
		source.position = courbe.sample_baked(d) + Vector3(0, 0.3, 0)
		add_child(source)
		Sons.boucle("eau", source, -9.0, 10.0)
		d += 16.0


## Une bande au sol qui suit une courbe, avec des bords qui s'estompent.
## « fondu » : sur cette longueur, la bande apparaît progressivement au départ.
func _ruban(courbe: Curve3D, demi_largeur: float, demi_largeur_bord: float, hauteur: float, mat: Material, fondu: float) -> MeshInstance3D:
	var points := courbe.get_baked_points()
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var decalages := [-demi_largeur_bord, -demi_largeur, demi_largeur, demi_largeur_bord]
	var opacites := [0.0, 1.0, 1.0, 0.0]
	var parcouru := 0.0
	for i in points.size():
		if i > 0:
			parcouru += points[i].distance_to(points[i - 1])
		var avant := points[max(i - 1, 0)]
		var apres := points[min(i + 1, points.size() - 1)]
		var tangente := (apres - avant).normalized()
		var cote := Vector3(-tangente.z, 0.0, tangente.x)
		# Une largeur qui varie un peu, pour un tracé moins régulier.
		var variation := 1.0 + sin(i * 0.37) * 0.12
		var apparition := 1.0 if fondu <= 0.0 else smoothstep(0.0, fondu, parcouru)
		for k in 4:
			outil.set_color(Color(1, 1, 1, opacites[k] * apparition))
			outil.set_normal(Vector3.UP)
			outil.set_uv(Vector2(k / 3.0, parcouru))
			outil.add_vertex(points[i] + cote * decalages[k] * variation + Vector3(0, hauteur, 0))
	for i in points.size() - 1:
		for k in 3:
			var a := i * 4 + k
			var b := a + 4
			outil.add_index(a)
			outil.add_index(a + 1)
			outil.add_index(b)
			outil.add_index(a + 1)
			outil.add_index(b + 1)
			outil.add_index(b)
	outil.generate_tangents()
	var bande := MeshInstance3D.new()
	bande.mesh = outil.commit()
	bande.material_override = mat
	bande.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return bande


## Des galets, quelques rochers et des herbes le long des deux rives.
func _creer_berges() -> void:
	var points := Chemin.courbe_ruisseau.get_baked_points()
	for i in range(1, points.size() - 1):
		var tangente := (points[i + 1] - points[i - 1]).normalized()
		var cote := Vector3(-tangente.z, 0.0, tangente.x)
		for s in [-1.0, 1.0]:
			var pos: Vector3 = points[i] + cote * s * _rng.randf_range(1.35, 2.0) + tangente * _rng.randf_range(-0.4, 0.4)
			if Chemin.distance_au_chemin(pos) < 2.2 or pos.distance_to(Chemin.PONT) < 4.0:
				continue
			var galet := Modeles.creer(GALETS[_rng.randi_range(0, 4)], Modeles.NATURE, TEINTE_PIERRE)
			galet.position = pos
			galet.rotation.y = _rng.randf_range(0.0, TAU)
			galet.scale = Vector3(1.0, 1.6, 1.0) * _rng.randf_range(1.0, 2.0)
			add_child(galet)
			if _rng.randf() < 0.12:
				var rocher := Modeles.creer("Rock_Medium_" + str(_rng.randi_range(1, 3)), Modeles.NATURE, TEINTE_PIERRE)
				rocher.position = pos + cote * s * 0.8
				rocher.rotation.y = _rng.randf_range(0.0, TAU)
				rocher.scale = Vector3.ONE * _rng.randf_range(0.2, 0.35)
				add_child(rocher)
			elif _rng.randf() < 0.25:
				var herbe := Modeles.creer("Grass_Wispy_Tall", Modeles.NATURE, TEINTE_HERBE)
				herbe.position = pos + cote * s * 0.6
				herbe.rotation.y = _rng.randf_range(0.0, TAU)
				herbe.scale = Vector3.ONE * _rng.randf_range(0.5, 0.8)
				add_child(herbe)


## Un parcours linéaire (demande de Tom) : des murs invisibles, cachés dans la forêt, à
## « distance_bordure » de chaque côté du chemin, et un cercle autour de la clairière
## ouvert seulement là où part le chemin. On peut marcher dans le ruisseau.
func _creer_bordures() -> void:
	var courbe := Chemin.courbe_chemin
	var longueur := courbe.get_baked_length()
	for cote in [-1.0, 1.0]:
		var avant := Vector3.INF
		var d := 0.0
		while d <= longueur:
			var p := courbe.sample_baked(d)
			var tangente := (courbe.sample_baked(min(d + 1.0, longueur)) - courbe.sample_baked(max(d - 1.0, 0.0))).normalized()
			var bord: Vector3 = p + Vector3(-tangente.z, 0, tangente.x) * cote * distance_bordure
			if Chemin.dans_bruneval(bord, 3.0):
				avant = Vector3.INF
			elif Vector2(bord.x, bord.z).length() > RAYON_CLAIRIERE - 1.0:
				if avant != Vector3.INF:
					_mur_invisible(avant, bord)
				avant = bord
			d += 3.0
	var morceaux := 48
	for i in morceaux:
		var a := Vector3.RIGHT.rotated(Vector3.UP, TAU * i / morceaux) * RAYON_CLAIRIERE
		var b := Vector3.RIGHT.rotated(Vector3.UP, TAU * (i + 1) / morceaux) * RAYON_CLAIRIERE
		if Chemin.distance_au_chemin((a + b) / 2.0) > distance_bordure - 1.0:
			_mur_invisible(a, b)
	# Autour de Bruneval : la limite suit le bord irrégulier de la clairière, cachée dans
	# les arbres, ouverte seulement là où arrive le chemin.
	morceaux = 72
	for i in morceaux:
		var a := Chemin.bord_bruneval(TAU * i / morceaux, 6.0)
		var b := Chemin.bord_bruneval(TAU * (i + 1) / morceaux, 6.0)
		if Chemin.distance_au_chemin((a + b) / 2.0) > distance_bordure - 1.0:
			_mur_invisible(a, b)


func _mur_invisible(a: Vector3, b: Vector3) -> void:
	var milieu := (a + b) / 2.0 + Vector3(0, 1.5, 0)
	var direction := b - a
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var forme := BoxShape3D.new()
	forme.size = Vector3(0.4, 3.0, direction.length() + 0.6)
	_ajouter_obstacle(forme, Transform3D(Basis.looking_at(direction.normalized()), milieu))


## Un vieux pont de bois fait main, légèrement bombé : deux troncs posés sur des pierres
## de chaque berge, des planches clouées une à une (largeurs inégales, un peu de
## travers, quelques-unes manquantes), et une rambarde de rondins sur des poteaux.
## On marche dessus (des pentes invisibles suivent la bosse).
func _creer_pont() -> void:
	const LONGUEUR := 7.0
	const LARGEUR := 1.9
	const BOSSE := 0.3
	var direction: Vector3 = Chemin.direction_pont
	var cote := Vector3(-direction.z, 0, direction.x)
	var repere := Basis(cote, Vector3.UP, -direction)
	var hauteur := func(t: float) -> float: return 0.04 + sin(t * PI) * BOSSE
	var ecorce := StandardMaterial3D.new()
	ecorce.albedo_texture = load("res://assets/nature/Bark_NormalTree.png")
	ecorce.normal_enabled = true
	ecorce.normal_texture = load("res://assets/nature/Bark_NormalTree_Normal.png")
	ecorce.albedo_color = Color(0.42, 0.38, 0.38)
	ecorce.roughness = 1.0
	var planche_mat := _bois.duplicate() as Material
	# Les deux troncs porteurs, sous les planches, qui suivent la bosse (en trois tronçons).
	for s in [-0.6, 0.6]:
		for k in 3:
			var t0 := k / 3.0
			var t1 := (k + 1) / 3.0
			var a: Vector3 = Chemin.PONT + direction * (t0 - 0.5) * (LONGUEUR + 0.6) + cote * s + Vector3.UP * (hauteur.call(t0) - 0.16)
			var b: Vector3 = Chemin.PONT + direction * (t1 - 0.5) * (LONGUEUR + 0.6) + cote * s + Vector3.UP * (hauteur.call(t1) - 0.16)
			add_child(_rondin(a, b, 0.13, ecorce))
	# Les planches.
	var t := 0.0
	var i := 0
	while t < 1.0:
		var epaisseur := _rng.randf_range(0.2, 0.3)
		var milieu := t + epaisseur / LONGUEUR / 2.0
		i += 1
		# Une planche manque de temps en temps (jamais aux deux bouts).
		if not (i % 7 == 4 and milieu > 0.15 and milieu < 0.85):
			var planche := MeshInstance3D.new()
			var boite := BoxMesh.new()
			boite.size = Vector3(LARGEUR * _rng.randf_range(0.92, 1.05), 0.05, epaisseur - 0.025)
			planche.mesh = boite
			planche.material_override = planche_mat
			var pente := atan(cos(milieu * PI) * PI * BOSSE / LONGUEUR)
			planche.basis = repere * Basis(Vector3.UP, _rng.randf_range(-0.05, 0.05)) * Basis(Vector3.RIGHT, pente)
			planche.position = Chemin.PONT + direction * (milieu - 0.5) * LONGUEUR + cote * _rng.randf_range(-0.05, 0.05) + Vector3.UP * hauteur.call(milieu)
			add_child(planche)
		t += epaisseur / LONGUEUR
	# Le sol du pont pour marcher : des pentes invisibles qui suivent le dessus des
	# planches, plus une petite rampe depuis le sol à chaque bout (pas de marche).
	var dessus := func(t: float) -> Vector3:
		var h: float = 0.0 if t < 0.0 or t > 1.0 else hauteur.call(t) + 0.025
		return Chemin.PONT + direction * (t - 0.5) * LONGUEUR + Vector3.UP * h
	var etapes := [-0.08, 0.0, 1.0 / 6.0, 2.0 / 6.0, 0.5, 4.0 / 6.0, 5.0 / 6.0, 1.0, 1.08]
	for k in etapes.size() - 1:
		var a: Vector3 = dessus.call(etapes[k])
		var b: Vector3 = dessus.call(etapes[k + 1])
		var forme := BoxShape3D.new()
		forme.size = Vector3(LARGEUR, 0.1, a.distance_to(b) + 0.05)
		_ajouter_obstacle(forme, Transform3D(Basis.looking_at((b - a).normalized()), (a + b) / 2.0 - Vector3(0, 0.05, 0)))
	# Les poteaux (aux deux bouts et au milieu) et la rambarde en rondins, de chaque côté.
	for s in [-1.0, 1.0]:
		var hauts := []
		for k in 3:
			var tp := k / 2.0
			var pied: Vector3 = Chemin.PONT + direction * (tp - 0.5) * (LONGUEUR - 0.3) + cote * s * (LARGEUR / 2.0 + 0.08)
			var haut: Vector3 = pied + Vector3.UP * (hauteur.call(tp) + 0.95)
			add_child(_rondin(pied - Vector3.UP * 0.2, haut, 0.07, ecorce))
			hauts.append(haut - Vector3.UP * 0.08)
		for k in 2:
			add_child(_rondin(hauts[k], hauts[k + 1], 0.045, ecorce))
	# Des pierres sous les bouts des troncs, à moitié dans la berge.
	for bout in [-1.0, 1.0]:
		for s in [-0.7, 0.7]:
			var pierre := Modeles.creer("Rock_Medium_" + str(_rng.randi_range(1, 3)), Modeles.NATURE, TEINTE_PIERRE)
			pierre.position = Chemin.PONT + direction * bout * (LONGUEUR / 2.0 + 0.1) + cote * s - Vector3.UP * 0.1
			pierre.rotation.y = _rng.randf_range(0.0, TAU)
			pierre.scale = Vector3.ONE * _rng.randf_range(0.18, 0.24)
			add_child(pierre)


## Un rondin (cylindre d'écorce) tendu entre deux points.
func _rondin(a: Vector3, b: Vector3, rayon: float, mat: Material) -> MeshInstance3D:
	var forme := CylinderMesh.new()
	forme.top_radius = rayon
	forme.bottom_radius = rayon * 1.1
	forme.height = a.distance_to(b)
	forme.radial_segments = 8
	var rondin := MeshInstance3D.new()
	rondin.mesh = forme
	rondin.material_override = mat
	var axe := (b - a).normalized()
	var x := axe.cross(Vector3.FORWARD if absf(axe.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	rondin.basis = Basis(x, axe, x.cross(axe))
	rondin.position = (a + b) / 2.0
	return rondin


func _creer_lanternes() -> void:
	var courbe := Chemin.courbe_chemin
	var longueur := courbe.get_baked_length()
	var cote_choisi := 1.0
	var distance := 8.0
	var fin_lanternes := courbe.get_closest_offset(Chemin.ENTREE) - 6.0
	while distance < fin_lanternes:
		var p := courbe.sample_baked(distance)
		var suite := courbe.sample_baked(min(distance + 1.0, longueur))
		var tangente := (suite - p).normalized()
		var cote := Vector3(-tangente.z, 0, tangente.x) * cote_choisi
		var pos := p + cote * 2.3
		# Jamais sur le pont, au bord de l'eau ou sur un lieu : on avance un peu plus loin.
		if not _place_pour_lanterne(pos):
			distance += 2.0
			continue
		_lanterne(pos, -cote)
		cote_choisi = -cote_choisi
		distance += ecart_lanternes


func _place_pour_lanterne(pos: Vector3) -> bool:
	if pos.distance_to(Chemin.PONT) < 6.0 or Chemin.distance_au_ruisseau(pos) < 3.5:
		return false
	return pos.distance_to(Chemin.RUINE) > 7.0 and pos.distance_to(Chemin.AUTEL) > 4.0 \
		and pos.distance_to(Chemin.CHARRETTE) > 5.0 and pos.distance_to(Chemin.ABRI) > 5.0


## Un poteau de bois avec une lanterne suspendue au-dessus du bord du sentier.
func _lanterne(pos: Vector3, vers_le_chemin: Vector3) -> void:
	var poteau := _poteau(2.4)
	poteau.position = pos + Vector3(0, 1.2, 0)
	add_child(poteau)
	var lanterne := Modeles.creer("Lantern_Wall")
	# Le modèle est fait pour un mur : sa potence part vers son +Z.
	lanterne.basis = Basis(Vector3.UP, atan2(vers_le_chemin.x, vers_le_chemin.z))
	lanterne.position = pos + Vector3(0, 0.95, 0)
	add_child(lanterne)
	var lumiere := OmniLight3D.new()
	lumiere.light_color = COULEUR_LANTERNE
	lumiere.light_energy = 1.1
	lumiere.omni_range = 6.0
	lumiere.position = pos + vers_le_chemin * 0.9 + Vector3(0, 1.4, 0)
	add_child(lumiere)
	var lueur := _flamme(0.07, 0.18)
	lueur.position = lumiere.position
	add_child(lueur)
	var forme := CylinderShape3D.new()
	forme.radius = 0.15
	forme.height = 2.4
	_ajouter_obstacle(forme, Transform3D(Basis(), pos + Vector3(0, 1.2, 0)))


## Une cabane de 4 m sur 4 à moitié effondrée (pièces du Medieval Village MegaKit) :
## il manque un pan de mur et la moitié du toit, la porte est tombée, un pan de mur gît
## au sol, et du lierre et des débris traînent. Sa porte regarde vers le chemin.
func _creer_ruine() -> void:
	var cabane := Node3D.new()
	cabane.position = Chemin.RUINE
	cabane.rotation.y = Chemin.ROTATION_RUINE
	add_child(cabane)
	# Les murs font 2 m de large ; [modèle, position du milieu, tourné d'un quart de tour].
	var murs := [
		["Wall_Plaster_Straight", Vector3(-1, 0, -2), false],
		["Wall_Plaster_Window_Wide_Flat", Vector3(1, 0, -2), false],
		["Wall_Plaster_Door_Flat", Vector3(-1, 0, 2), false],
		["Wall_Plaster_WoodGrid", Vector3(-2, 0, -1), true],
		["Wall_Plaster_Straight", Vector3(-2, 0, 1), true],
		["Wall_Plaster_Straight", Vector3(2, 0, -1), true],
	]
	for m in murs:
		var mur := Modeles.creer(m[0])
		mur.position = m[1]
		if m[2]:
			mur.rotation.y = PI / 2.0
		cabane.add_child(mur)
		var forme := BoxShape3D.new()
		forme.size = Vector3(2.0, 3.0, 0.3)
		_ajouter_obstacle(forme, cabane.transform * Transform3D(mur.basis, m[1] + Vector3(0, 1.5, 0)))
	# Le pan de mur effondré, couché devant la cabane.
	var tombe := Modeles.creer("Wall_Plaster_Straight")
	tombe.position = Vector3(1.2, 0.15, 2.3)
	tombe.basis = Basis(Vector3.UP, 0.25) * Basis(Vector3.RIGHT, PI / 2.0 - 0.12)
	cabane.add_child(tombe)
	# Les poteaux d'angle, dont un penché.
	for coin in [Vector3(-2, 0, -2), Vector3(2, 0, -2), Vector3(-2, 0, 2), Vector3(2, 0, 2)]:
		var poteau := Modeles.creer("Corner_Exterior_Wood")
		poteau.position = coin
		if coin == Vector3(2, 0, 2):
			poteau.basis = Basis(Vector3.FORWARD, -0.45)
		cabane.add_child(poteau)
	# Le plancher, avec un trou.
	for case in [Vector3(-1, 0.02, -1), Vector3(1, 0.02, -1), Vector3(-1, 0.02, 1)]:
		var plancher := Modeles.creer("Floor_WoodDark")
		plancher.position = case
		cabane.add_child(plancher)
	# La moitié du toit tient encore, l'autre moitié est tombée.
	for x in [-1.0, 1.0]:
		var toit := Modeles.creer("Roof_Wooden_2x1_Middle")
		toit.position = Vector3(x, 2.2, -1)
		cabane.add_child(toit)
	var morceau := Modeles.creer("Roof_Wooden_2x1_Middle")
	morceau.position = Vector3(0.8, 1.2, 0.6)
	morceau.basis = Basis(Vector3.RIGHT, 0.55)
	cabane.add_child(morceau)
	# La porte arrachée, par terre.
	var porte := Modeles.creer("Door_1_Flat")
	porte.position = Vector3(-1.3, 0.08, 3.0)
	porte.basis = Basis(Vector3.UP, 0.4) * Basis(Vector3.RIGHT, -PI / 2.0)
	cabane.add_child(porte)
	# Du lierre sur les murs et quelques débris.
	for v in [["Prop_Vine1", Vector3(-1.0, 2.9, -2.2)], ["Prop_Vine4", Vector3(-2.2, 2.4, 0.8)]]:
		var lierre := Modeles.creer(v[0], Modeles.OBJETS, TEINTE_HERBE)
		lierre.position = v[1]
		cabane.add_child(lierre)
	for d in [["Prop_Brick1", Vector3(0.4, 0.1, 2.9), 0.3], ["Prop_Brick2", Vector3(1.9, 0.1, 3.2), 1.2],
			["Prop_Brick3", Vector3(-0.2, 0.1, 3.4), 2.0], ["Crate_Wooden", Vector3(1.0, 0.0, -0.9), 0.4],
			["Barrel", Vector3(-1.2, 0.0, -1.1), 0.0], ["Vase_Rubble_Medium", Vector3(0.6, 0.02, 1.0), 0.8]]:
		var objet := Modeles.creer(d[0])
		objet.position = d[1]
		objet.rotation.y = d[2]
		cabane.add_child(objet)


## Un vieil autel de pierre brute avec un cristal rouge : premier signe de la malédiction.
func _creer_autel() -> void:
	var pierre := Modeles.creer("Rock_Medium_2", Modeles.NATURE, TEINTE_PIERRE)
	pierre.position = Chemin.AUTEL
	pierre.scale = Vector3(0.42, 0.5, 0.42)
	add_child(pierre)
	for i in 6:
		var brique := Modeles.creer("Prop_Brick" + str(1 + i % 3))
		var a := i * TAU / 6.0
		brique.position = Chemin.AUTEL + Vector3(cos(a) * 1.3, 0.1, sin(a) * 1.1)
		brique.rotation = Vector3(0.3, a, 0.2)
		add_child(brique)
	var cristal := _flamme(0.14, 0.45, COULEUR_MAUDITE)
	cristal.position = Chemin.AUTEL + Vector3(0.0, 1.2, 0)
	add_child(cristal)
	_lumiere_autel = OmniLight3D.new()
	_lumiere_autel.light_color = COULEUR_MAUDITE
	_lumiere_autel.light_energy = 1.2
	_lumiere_autel.omni_range = 5.0
	_lumiere_autel.position = Chemin.AUTEL + Vector3(0, 1.5, 0)
	add_child(_lumiere_autel)
	var forme := CylinderShape3D.new()
	forme.radius = 0.9
	forme.height = 2.0
	_ajouter_obstacle(forme, Transform3D(Basis(), Chemin.AUTEL + Vector3(0, 1, 0)))


## Deux torches sur des poteaux marquent l'arrivée à Bruneval, à l'entrée du hameau.
func _creer_torches_entree() -> void:
	var courbe := Chemin.courbe_chemin
	var longueur := courbe.get_baked_length()
	var a_l_entree := courbe.get_closest_offset(Chemin.ENTREE)
	var fin := courbe.sample_baked(a_l_entree)
	var tangente := (fin - courbe.sample_baked(a_l_entree - 1.0)).normalized()
	var cote := Vector3(-tangente.z, 0, tangente.x)
	for s in [-1.0, 1.0]:
		var pos: Vector3 = fin + cote * s * 2.4
		var poteau := _poteau(2.2)
		poteau.position = pos + Vector3(0, 1.1, 0)
		add_child(poteau)
		var torche := Modeles.creer("Torch_Metal")
		torche.basis = Basis(Vector3.UP, atan2(tangente.x, tangente.z))
		torche.position = pos + Vector3(0, 1.9, 0)
		add_child(torche)
		var flamme := _flamme(0.12, 0.4)
		flamme.position = pos + tangente * 0.3 + Vector3(0, 2.25, 0)
		add_child(flamme)
		var lumiere := OmniLight3D.new()
		lumiere.light_color = Color("e0823a")
		lumiere.light_energy = 1.6
		lumiere.omni_range = 7.0
		lumiere.position = flamme.position + Vector3(0, 0.2, 0)
		add_child(lumiere)
		var forme := CylinderShape3D.new()
		forme.radius = 0.15
		forme.height = 2.4
		_ajouter_obstacle(forme, Transform3D(Basis(), pos + Vector3(0, 1.2, 0)))


## Un poteau rond, habillé du même bois que les objets du pack.
func _poteau(hauteur: float) -> MeshInstance3D:
	var forme := CylinderMesh.new()
	forme.top_radius = 0.07
	forme.bottom_radius = 0.09
	forme.height = hauteur
	forme.radial_segments = 7
	var poteau := MeshInstance3D.new()
	poteau.mesh = forme
	poteau.material_override = _bois
	return poteau


## Une petite flamme (ou un cristal) qui brille sans être touchée par les ombres.
func _flamme(largeur: float, hauteur: float, couleur := COULEUR_LANTERNE) -> MeshInstance3D:
	var forme := CylinderMesh.new()
	forme.top_radius = 0.0
	forme.bottom_radius = largeur
	forme.height = hauteur
	forme.radial_segments = 6
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = couleur
	var flamme := MeshInstance3D.new()
	flamme.mesh = forme
	flamme.material_override = mat
	flamme.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return flamme


func _ajouter_obstacle(forme: Shape3D, transfo: Transform3D) -> void:
	var zone := CollisionShape3D.new()
	zone.shape = forme
	var corps := StaticBody3D.new()
	corps.transform = transfo
	corps.add_child(zone)
	add_child(corps)
