extends Node3D
## Tout ce qu'on voit le long du chemin (le tracé est dans chemin.gd) :
## le sentier de terre, les lanternes, le ruisseau et ses berges, le pont, la ruine
## de briques, l'autel abandonné à la lueur rouge, la charrette renversée et les
## torches de l'entrée de Bruneval. Les objets viennent des packs Quaternius
## (Medieval Village MegaKit et Fantasy Props MegaKit).

## Écart entre deux lanternes (en mètres).
@export var ecart_lanternes := 14.0
## Longueur sur laquelle le sentier apparaît doucement en sortant de la clairière.
@export var fondu_depart := 7.0

const COULEUR_TERRE := Color("3a2f29")
const COULEUR_TERRE_MOUILLEE := Color("1f1813")
const COULEUR_LANTERNE := Color("f0ad55")
const COULEUR_MAUDITE := Color("b0303a")
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
	_creer_berges()
	_bloquer_le_ruisseau()
	_creer_pont()
	_creer_lanternes()
	_creer_ruine()
	_creer_autel()
	_creer_torches_entree()
	var charrette := Node3D.new()
	charrette.set_script(load("res://scripts/charrette.gd"))
	charrette.position = Chemin.CHARRETTE
	add_child(charrette)


## La lueur rouge de l'autel palpite lentement : la malédiction n'est pas loin.
func _process(delta: float) -> void:
	_temps += delta
	_lumiere_autel.light_energy = 1.2 + sin(_temps * 1.3) * 0.35


func _sentier() -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = COULEUR_TERRE
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	return _ruban(Chemin.courbe_chemin, 0.9, 1.7, 0.03, mat, fondu_depart)


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


## On ne peut pas traverser le ruisseau à pied : il faut passer par le pont.
func _bloquer_le_ruisseau() -> void:
	var points := Chemin.courbe_ruisseau.get_baked_points()
	for i in range(0, points.size() - 1, 2):
		if points[i].distance_to(Chemin.PONT) < 3.2:
			continue
		var direction := (points[min(i + 2, points.size() - 1)] - points[i]).normalized()
		var bloc := BoxShape3D.new()
		bloc.size = Vector3(2.4, 2.0, 2.4)
		_ajouter_obstacle(bloc, Transform3D(Basis.looking_at(direction), points[i] + Vector3(0, 1, 0)))


## Un pont de planches avec des barrières en bois de chaque côté.
func _creer_pont() -> void:
	var direction: Vector3 = Chemin.direction_pont
	var cote := Vector3(-direction.z, 0, direction.x)
	var angle := atan2(-direction.z, direction.x)
	for i in 3:
		var plancher := Modeles.creer("Floor_WoodDark")
		plancher.position = Chemin.PONT + direction * (i - 1) * 2.0 + Vector3(0, 0.1, 0)
		plancher.rotation.y = angle
		plancher.scale = Vector3(1.0, 1.0, 1.25)
		add_child(plancher)
	for s in [-1.0, 1.0]:
		for i in 3:
			var barriere := Modeles.creer("Prop_WoodenFence_Single")
			barriere.position = Chemin.PONT + direction * (i - 1) * 2.0 + cote * s * 1.3 + Vector3(0, 0.1, 0)
			barriere.rotation.y = angle
			add_child(barriere)
		var garde := BoxShape3D.new()
		garde.size = Vector3(0.2, 2.0, 6.2)
		_ajouter_obstacle(garde, Transform3D(Basis.looking_at(direction), Chemin.PONT + cote * s * 1.35 + Vector3(0, 1, 0)))


func _creer_lanternes() -> void:
	var courbe := Chemin.courbe_chemin
	var longueur := courbe.get_baked_length()
	var cote_choisi := 1.0
	var distance := 8.0
	while distance < longueur - 6.0:
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
		and pos.distance_to(Chemin.CHARRETTE) > 5.0


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
	cabane.rotation.y = 0.69
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


## Deux torches sur des poteaux marquent l'arrivée à Bruneval, au bout du chemin.
func _creer_torches_entree() -> void:
	var courbe := Chemin.courbe_chemin
	var longueur := courbe.get_baked_length()
	var fin := courbe.sample_baked(longueur)
	var tangente := (fin - courbe.sample_baked(longueur - 1.0)).normalized()
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
