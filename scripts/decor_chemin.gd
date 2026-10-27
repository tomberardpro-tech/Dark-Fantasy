extends Node3D
## Tout ce qu'on voit le long du chemin (le tracé est dans chemin.gd) :
## le sentier de terre, les lanternes, le ruisseau et son pont, la ruine moussue,
## l'autel abandonné à la lueur rouge, la charrette renversée et les torches de l'entrée
## de Bruneval.

## Écart entre deux lanternes (en mètres).
@export var ecart_lanternes := 14.0

const COULEUR_TERRE := Color("3a2f29")
const COULEUR_EAU := Color("0e1229")
const COULEUR_BOIS := Color("4a3b31")
const COULEUR_BOIS_SOMBRE := Color("2a221f")
const COULEUR_PIERRE := Color("4b5160")
const COULEUR_MOUSSE := Color("3a4a43")
const COULEUR_LANTERNE := Color("f0ad55")
const COULEUR_MAUDITE := Color("b0303a")

var _lumiere_autel: OmniLight3D
var _temps := 0.0


func _ready() -> void:
	add_child(_ruban(Chemin.courbe_chemin, 0.9, 1.6, COULEUR_TERRE, 0.03, false))
	add_child(_ruban(Chemin.courbe_ruisseau, 1.2, 1.7, COULEUR_EAU, 0.04, true))
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


## Une bande au sol qui suit une courbe, avec des bords qui s'estompent.
func _ruban(courbe: Curve3D, demi_largeur: float, demi_largeur_bord: float, couleur: Color, hauteur: float, eau: bool) -> MeshInstance3D:
	var points := courbe.get_baked_points()
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var decalages := [-demi_largeur_bord, -demi_largeur, demi_largeur, demi_largeur_bord]
	var opacites := [0.0, 1.0, 1.0, 0.0]
	for i in points.size():
		var avant := points[max(i - 1, 0)]
		var apres := points[min(i + 1, points.size() - 1)]
		var tangente := (apres - avant).normalized()
		var cote := Vector3(-tangente.z, 0.0, tangente.x)
		# Une largeur qui varie un peu, pour un tracé moins régulier.
		var variation := 1.0 + sin(i * 0.37) * 0.12
		for k in 4:
			outil.set_color(Color(1, 1, 1, opacites[k]))
			outil.set_normal(Vector3.UP)
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
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = couleur
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if eau:
		# Eau sombre et calme qui reflète la lune.
		mat.roughness = 0.08
		mat.metallic = 0.3
		mat.metallic_specular = 0.9
	else:
		mat.roughness = 1.0
	var bande := MeshInstance3D.new()
	bande.mesh = outil.commit()
	bande.material_override = mat
	bande.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return bande


## On ne peut pas traverser le ruisseau à pied : il faut passer par le pont.
func _bloquer_le_ruisseau() -> void:
	var points := Chemin.courbe_ruisseau.get_baked_points()
	for i in range(0, points.size() - 1, 2):
		if points[i].distance_to(Chemin.PONT) < 2.6:
			continue
		var direction := (points[min(i + 2, points.size() - 1)] - points[i]).normalized()
		var bloc := BoxShape3D.new()
		bloc.size = Vector3(2.2, 2.0, 2.4)
		_ajouter_obstacle(bloc, Transform3D(Basis.looking_at(direction), points[i] + Vector3(0, 1, 0)))


func _creer_pont() -> void:
	var direction: Vector3 = Chemin.direction_pont
	var cote := Vector3(-direction.z, 0, direction.x)
	var base := Transform3D(Basis.looking_at(direction), Chemin.PONT)
	var bois := _materiau(COULEUR_BOIS)
	var bois_sombre := _materiau(COULEUR_BOIS_SOMBRE)
	# Les planches du tablier.
	for i in 7:
		var planche := _boite(Vector3(2.4, 0.08, 0.55), bois if i % 2 == 0 else bois_sombre)
		planche.transform = base * Transform3D(Basis(), Vector3(0, 0.1, -2.1 + i * 0.7))
		add_child(planche)
	# Les deux rambardes, avec leurs poteaux.
	for s in [-1.0, 1.0]:
		var rambarde := _boite(Vector3(0.1, 0.1, 4.6), bois_sombre)
		rambarde.transform = base * Transform3D(Basis(), Vector3(s * 1.2, 0.85, 0))
		add_child(rambarde)
		for z in [-2.2, 0.0, 2.2]:
			var poteau := _boite(Vector3(0.12, 0.9, 0.12), bois_sombre)
			poteau.transform = base * Transform3D(Basis(), Vector3(s * 1.2, 0.45, z))
			add_child(poteau)
		var garde := BoxShape3D.new()
		garde.size = Vector3(0.2, 2.0, 4.6)
		_ajouter_obstacle(garde, Transform3D(base.basis, Chemin.PONT + cote * s * 1.25 + Vector3(0, 1, 0)))


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
		_lanterne(p + cote * 1.9)
		cote_choisi = -cote_choisi
		distance += ecart_lanternes


func _lanterne(pos: Vector3) -> void:
	var poteau := _cylindre(0.05, 0.07, 1.6, _materiau(COULEUR_BOIS_SOMBRE))
	poteau.position = pos + Vector3(0, 0.8, 0)
	add_child(poteau)
	var cage := _boite(Vector3(0.26, 0.3, 0.26), _materiau_brillant(COULEUR_LANTERNE))
	cage.position = pos + Vector3(0, 1.72, 0)
	add_child(cage)
	var toit := _boite(Vector3(0.34, 0.06, 0.34), _materiau(COULEUR_BOIS_SOMBRE))
	toit.position = pos + Vector3(0, 1.9, 0)
	add_child(toit)
	var lumiere := OmniLight3D.new()
	lumiere.light_color = COULEUR_LANTERNE
	lumiere.light_energy = 1.0
	lumiere.omni_range = 5.5
	lumiere.position = pos + Vector3(0, 1.7, 0)
	add_child(lumiere)
	var forme := CylinderShape3D.new()
	forme.radius = 0.15
	forme.height = 2.0
	_ajouter_obstacle(forme, Transform3D(Basis(), pos + Vector3(0, 1, 0)))


## Quelques pans de murs effondrés, couverts de mousse, et des blocs tombés.
func _creer_ruine() -> void:
	var pierre := _materiau(COULEUR_PIERRE)
	var mousse := _materiau(COULEUR_MOUSSE)
	# [position par rapport au centre, taille, rotation]
	var murs := [
		[Vector3(-2.0, 0, -1.5), Vector3(4.0, 2.4, 0.6), 0.1],
		[Vector3(1.6, 0, -1.2), Vector3(2.2, 1.4, 0.6), 0.1],
		[Vector3(-3.6, 0, 0.8), Vector3(0.6, 1.8, 3.4), 0.1],
		[Vector3(2.4, 0, 2.2), Vector3(2.6, 0.9, 0.6), -0.2],
	]
	for m in murs:
		var taille: Vector3 = m[1]
		var transfo := Transform3D(Basis(Vector3.UP, m[2]), Chemin.RUINE + m[0] + Vector3(0, taille.y / 2.0, 0))
		var mur := _boite(taille, pierre)
		mur.transform = transfo
		add_child(mur)
		var dessus := _boite(Vector3(taille.x + 0.08, 0.12, taille.z + 0.08), mousse)
		dessus.transform = transfo * Transform3D(Basis(), Vector3(0, taille.y / 2.0, 0))
		add_child(dessus)
		var forme := BoxShape3D.new()
		forme.size = taille
		_ajouter_obstacle(forme, transfo)
	for i in 4:
		var bloc := _boite(Vector3(0.7, 0.5, 0.6), pierre)
		bloc.position = Chemin.RUINE + Vector3(-1.0 + i * 0.9, 0.25, 0.6 + (i % 2) * 0.8)
		bloc.rotation = Vector3(0.2 * i, 0.7 * i, 0.1)
		add_child(bloc)


## Un vieil autel de pierre avec un cristal rouge : premier signe de la malédiction.
func _creer_autel() -> void:
	var pierre := _materiau(Color("5d6372"))
	var socle := _boite(Vector3(1.4, 0.9, 0.9), pierre)
	socle.position = Chemin.AUTEL + Vector3(0, 0.45, 0)
	add_child(socle)
	var dalle := _boite(Vector3(1.7, 0.15, 1.1), pierre)
	dalle.position = Chemin.AUTEL + Vector3(0, 0.97, 0)
	dalle.rotation.z = 0.06
	add_child(dalle)
	var cristal := _boite(Vector3(0.22, 0.4, 0.22), _materiau_brillant(COULEUR_MAUDITE))
	cristal.position = Chemin.AUTEL + Vector3(0.2, 1.25, 0)
	cristal.rotation = Vector3(0.0, 0.785, 0.785)
	add_child(cristal)
	_lumiere_autel = OmniLight3D.new()
	_lumiere_autel.light_color = COULEUR_MAUDITE
	_lumiere_autel.light_energy = 1.2
	_lumiere_autel.omni_range = 5.0
	_lumiere_autel.position = Chemin.AUTEL + Vector3(0.2, 1.4, 0)
	add_child(_lumiere_autel)
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.7, 2.0, 1.1)
	_ajouter_obstacle(forme, Transform3D(Basis(), Chemin.AUTEL + Vector3(0, 1, 0)))


## Deux torches marquent l'arrivée à Bruneval, au bout du chemin.
func _creer_torches_entree() -> void:
	var courbe := Chemin.courbe_chemin
	var longueur := courbe.get_baked_length()
	var fin := courbe.sample_baked(longueur)
	var tangente := (fin - courbe.sample_baked(longueur - 1.0)).normalized()
	var cote := Vector3(-tangente.z, 0, tangente.x)
	for s in [-1.0, 1.0]:
		var pos: Vector3 = fin + cote * s * 2.4
		var poteau := _cylindre(0.07, 0.09, 2.2, _materiau(COULEUR_BOIS_SOMBRE))
		poteau.position = pos + Vector3(0, 1.1, 0)
		add_child(poteau)
		var flamme := _cylindre(0.0, 0.14, 0.45, _materiau_brillant(Color("f0ad55")))
		flamme.position = pos + Vector3(0, 2.45, 0)
		add_child(flamme)
		var lumiere := OmniLight3D.new()
		lumiere.light_color = Color("e0823a")
		lumiere.light_energy = 1.6
		lumiere.omni_range = 7.0
		lumiere.position = pos + Vector3(0, 2.4, 0)
		add_child(lumiere)
		var forme := CylinderShape3D.new()
		forme.radius = 0.15
		forme.height = 2.4
		_ajouter_obstacle(forme, Transform3D(Basis(), pos + Vector3(0, 1.2, 0)))


func _ajouter_obstacle(forme: Shape3D, transfo: Transform3D) -> void:
	var zone := CollisionShape3D.new()
	zone.shape = forme
	var corps := StaticBody3D.new()
	corps.transform = transfo
	corps.add_child(zone)
	add_child(corps)


func _boite(taille: Vector3, mat: Material) -> MeshInstance3D:
	var forme := BoxMesh.new()
	forme.size = taille
	var objet := MeshInstance3D.new()
	objet.mesh = forme
	objet.material_override = mat
	return objet


func _cylindre(haut: float, bas: float, hauteur: float, mat: Material) -> MeshInstance3D:
	var forme := CylinderMesh.new()
	forme.top_radius = haut
	forme.bottom_radius = bas
	forme.height = hauteur
	forme.radial_segments = 6
	var objet := MeshInstance3D.new()
	objet.mesh = forme
	objet.material_override = mat
	return objet


func _materiau(couleur: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mat.roughness = 1.0
	return mat


func _materiau_brillant(couleur: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = couleur
	return mat
