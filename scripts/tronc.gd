extends StaticBody3D
## Tronc près d'un feu de camp. Touche E à côté : s'asseoir ou se relever.
## S'asseoir au feu sauvegarde la partie (voir sauvegarde.gd).
## Au lancement, le personnage est assis au dernier feu utilisé, ou au feu de départ
## s'il n'y a pas encore de sauvegarde.

## Nom unique de ce feu de camp, utilisé dans la sauvegarde.
@export var nom_du_feu := "clairiere"
## Est-ce le feu où commence une nouvelle partie ?
@export var feu_de_depart := true
## Distance à laquelle le message « E : s'asseoir » apparaît.
@export var distance_interaction := 1.8


func _ready() -> void:
	add_to_group("interactif")
	_habiller_d_ecorce()
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur == null:
		return
	var reprendre_ici: bool = Sauvegarde.dernier_feu() == nom_du_feu
	var nouvelle_partie: bool = not Sauvegarde.existe() and feu_de_depart and joueur.assis_au_depart
	if reprendre_ici or nouvelle_partie:
		joueur.asseoir.call_deferred(point_assise(), regard(), true, self)


## Utilisé par le joueur pour savoir s'il peut interagir avec ce tronc.
func distance_pour_interagir(joueur: Node3D) -> float:
	if joueur.est_assis:
		return 0.0 if joueur.siege == self else INF
	var d := joueur.global_position.distance_to(point_assise())
	return d if d < distance_interaction else INF


func texte_interaction(joueur: Node3D) -> String:
	return "E : se relever" if joueur.est_assis else "E : s'asseoir"


func interagir(joueur: Node3D) -> void:
	if joueur.est_assis:
		joueur.se_relever()
		return
	joueur.asseoir(point_assise(), regard(), false, self)
	Sauvegarde.sauvegarder(nom_du_feu, point_assise(), {"epee": joueur.a_epee})
	var interface := get_tree().get_first_node_in_group("interface")
	# Pas de message tant que la sauvegarde sur le disque est coupée (voir sauvegarde.gd).
	if interface and Sauvegarde.SUR_LE_DISQUE:
		interface.notifier("Partie sauvegardée")


## Un rondin simple et net (choix de Tom) : bien rond, à peine irrégulier, un peu plus épais d'un
## côté, habillé de l'écorce brune des pins du pack nature, avec les bouts coupés qui
## montrent les cernes du bois.
func _habiller_d_ecorce() -> void:
	var apparence := get_node_or_null("Apparence") as MeshInstance3D
	if apparence == null:
		return
	var ecorce := StandardMaterial3D.new()
	ecorce.albedo_texture = load("res://assets/nature/Bark_NormalTree.png")
	ecorce.normal_enabled = true
	ecorce.normal_texture = load("res://assets/nature/Bark_NormalTree_Normal.png")
	ecorce.albedo_color = Color(0.72, 0.58, 0.48)
	ecorce.roughness = 1.0
	var bois_coupe := ShaderMaterial.new()
	bois_coupe.shader = load("res://shaders/bois_coupe.gdshader")
	apparence.mesh = _maillage_rondin(ecorce, bois_coupe)
	apparence.material_override = null


## Fabrique le rondin : un tube bosselé (l'écorce) fermé par deux bouts plats (le bois coupé).
## Son axe est le Y du maillage (le nœud « Apparence » le couche à l'horizontale).
func _maillage_rondin(ecorce: Material, bois_coupe: Material) -> ArrayMesh:
	const LONGUEUR := 1.6
	const TOURS := 24
	const ANNEAUX := 14
	var bruit := FastNoiseLite.new()
	bruit.seed = 5
	bruit.frequency = 0.9
	var rayon := func(angle: float, t: float) -> float:
		var base := lerpf(0.23, 0.215, t)
		var p := Vector2(cos(angle), sin(angle)) * 1.5
		return base * (1.0 + bruit.get_noise_3d(p.x, p.y, t * 4.0) * 0.025)
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in ANNEAUX + 1:
		var t := float(a) / ANNEAUX
		for k in TOURS + 1:
			var angle := TAU * k / TOURS
			var r: float = rayon.call(angle, t)
			outil.set_uv(Vector2(float(k) / TOURS * 2.0, t * 2.2))
			outil.add_vertex(Vector3(cos(angle) * r, (t - 0.5) * LONGUEUR, sin(angle) * r))
	for a in ANNEAUX:
		for k in TOURS:
			var i := a * (TOURS + 1) + k
			var j := i + TOURS + 1
			outil.add_index(i)
			outil.add_index(j)
			outil.add_index(i + 1)
			outil.add_index(i + 1)
			outil.add_index(j)
			outil.add_index(j + 1)
	outil.generate_normals()
	outil.generate_tangents()
	var maillage := outil.commit()
	maillage.surface_set_material(0, ecorce)
	# Les deux bouts coupés.
	var bouts := SurfaceTool.new()
	bouts.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cote in [0.0, 1.0]:
		var y: float = (cote - 0.5) * LONGUEUR
		var normale := Vector3(0, 1 if cote > 0.5 else -1, 0)
		for k in TOURS:
			var a1 := TAU * k / TOURS
			var a2 := TAU * (k + 1) / TOURS
			var r1: float = rayon.call(a1, cote)
			var r2: float = rayon.call(a2, cote)
			var points := [Vector3(0, y, 0), Vector3(cos(a1) * r1, y, sin(a1) * r1), Vector3(cos(a2) * r2, y, sin(a2) * r2)]
			if cote < 0.5:
				points = [points[0], points[2], points[1]]
			for p in points:
				bouts.set_normal(normale)
				# UV : position sur le disque, de -1 à 1, pour dessiner les cernes.
				bouts.set_uv(Vector2(p.x, p.z) / 0.235)
				bouts.add_vertex(p)
	bouts.commit(maillage)
	maillage.surface_set_material(1, bois_coupe)
	return maillage


## Vrai si c'est ici que le héros doit se réveiller (dernier feu utilisé, ou feu de départ).
func est_le_dernier_feu() -> bool:
	if Sauvegarde.existe():
		return Sauvegarde.dernier_feu() == nom_du_feu
	return feu_de_depart


## Après sa mort, le héros se réveille assis ici.
func reveiller_au_feu(joueur: Node3D) -> void:
	joueur.asseoir(point_assise(), regard(), true, self)


## L'endroit où se place le personnage assis : juste devant le tronc, côté feu.
func point_assise() -> Vector3:
	return global_transform * Vector3(0.0, 0.0, 0.65)


## La direction du regard du personnage assis : vers le feu.
func regard() -> Vector3:
	return global_basis.z.normalized()
