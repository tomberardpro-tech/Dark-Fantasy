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


## Un vieux tronc d'arbre tombé (choix de Tom) : épais et noueux, un peu tordu, avec ses
## racines qui s'évasent à un bout, une cassure en dents de scie à l'autre (le bois clair
## avec ses cernes), des moignons de branches cassées côté forêt, et de la mousse sur le
## dessus. L'écorce est celle des pins du pack nature.
## Le milieu (là où le héros s'assoit) garde la hauteur de l'ancien rondin.
func _habiller_d_ecorce() -> void:
	var apparence := get_node_or_null("Apparence") as MeshInstance3D
	if apparence == null:
		return
	var ecorce := StandardMaterial3D.new()
	ecorce.albedo_texture = load("res://assets/nature/Bark_NormalTree.png")
	ecorce.normal_enabled = true
	ecorce.normal_texture = load("res://assets/nature/Bark_NormalTree_Normal.png")
	ecorce.normal_scale = 1.4
	ecorce.albedo_color = Color(0.7, 0.57, 0.48)
	# La mousse est peinte dans la couleur des sommets (vert sur le dessus, ailleurs blanc).
	ecorce.vertex_color_use_as_albedo = true
	ecorce.roughness = 1.0
	var bois_coupe := ShaderMaterial.new()
	bois_coupe.shader = load("res://shaders/bois_coupe.gdshader")
	apparence.mesh = _maillage_tronc(ecorce, bois_coupe)
	apparence.material_override = null


## Dans le maillage, l'axe du tronc est Y (de -LONGUEUR/2 à +LONGUEUR/2), le dessus est +X
## (le nœud « Apparence » couche le tronc), le côté du héros est +Z, la forêt est -Z.
const LONGUEUR := 2.1
const TOURS := 28
const ANNEAUX := 30
var _bruit := FastNoiseLite.new()
## Le nombre de sommets déjà posés (pour relier les moignons de branches).
var _sommets := 0


## Le rayon du tronc à l'angle « angle » et à la position « t » (0 : racines, 1 : cassure).
func _rayon(angle: float, t: float) -> float:
	var base := 0.235
	# Les racines : le tronc s'évase et se creuse en contreforts.
	var evase := pow(1.0 - smoothstep(0.0, 0.22, t), 2.0)
	var contreforts := pow(maxf(cos(angle * 5.0 + 0.4), 0.0), 2.0)
	base += evase * (0.13 + contreforts * 0.16)
	# Vers la cassure, il s'amincit un peu.
	base *= lerpf(1.0, 0.86, smoothstep(0.5, 1.0, t))
	# Des nœuds et des bosses.
	var p := Vector2(cos(angle), sin(angle)) * 1.3
	var bosses := _bruit.get_noise_3d(p.x, p.y, t * 6.0) * 0.07
	var noeuds := pow(maxf(_bruit.get_noise_3d(p.x * 2.0, p.y * 2.0, t * 14.0 + 30.0), 0.0), 2.0) * 0.5
	return base * (1.0 + bosses + noeuds)


## L'axe du tronc, légèrement courbé (il monte un peu au milieu, part de côté au bout).
func _axe(t: float) -> Vector3:
	return Vector3(sin(t * PI) * 0.025, (t - 0.5) * LONGUEUR, sin(t * PI * 0.8) * -0.04)


## La cassure du bout : une hauteur en dents de scie selon l'angle.
func _cassure(angle: float) -> float:
	return (sin(angle * 3.0) * 0.5 + sin(angle * 7.0 + 1.3) * 0.35 + _bruit.get_noise_1d(angle * 4.0) * 0.6) * 0.07


func _maillage_tronc(ecorce: Material, bois_coupe: Material) -> ArrayMesh:
	_bruit.seed = 11
	_bruit.frequency = 0.8
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mousse := Color(0.55, 0.78, 0.42)
	for a in ANNEAUX + 1:
		var t := float(a) / ANNEAUX
		for k in TOURS + 1:
			var angle := TAU * k / TOURS
			var r := _rayon(angle, t)
			var pos := _axe(t) + Vector3(cos(angle) * r, 0, sin(angle) * r)
			if a == ANNEAUX:
				pos.y += _cassure(angle)
			# De la mousse sur le dessus (+X), par plaques.
			var dessus := smoothstep(0.35, 0.9, cos(angle))
			var plaques := smoothstep(-0.1, 0.35, _bruit.get_noise_3d(cos(angle) * 3.0, sin(angle) * 3.0, t * 9.0 + 50.0))
			outil.set_color(Color.WHITE.lerp(mousse, dessus * plaques * 0.85))
			outil.set_uv(Vector2(float(k) / TOURS * 2.0, t * 2.8))
			outil.add_vertex(pos)
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
	_sommets = (ANNEAUX + 1) * (TOURS + 1)
	# Les moignons de branches cassées, côté forêt et sur le dessus (jamais côté héros).
	for branche in [[0.42, PI * 1.72, 0.075, 0.32], [0.7, PI * 1.52, 0.06, 0.24], [0.28, PI * 1.9, 0.05, 0.18]]:
		_moignon(outil, branche[0], branche[1], branche[2], branche[3])
	outil.generate_normals()
	outil.generate_tangents()
	var maillage := outil.commit()
	maillage.surface_set_material(0, ecorce)
	# Les deux bouts : le dessous des racines (écorce sombre) et la cassure (bois clair).
	var bouts := SurfaceTool.new()
	bouts.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cote in [0.0, 1.0]:
		var centre := _axe(cote)
		var normale := Vector3(0, 1 if cote > 0.5 else -1, 0)
		if cote > 0.5:
			centre.y += 0.05
		for k in TOURS:
			var a1 := TAU * k / TOURS
			var a2 := TAU * (k + 1) / TOURS
			var p1 := _axe(cote) + Vector3(cos(a1), 0, sin(a1)) * _rayon(a1, cote)
			var p2 := _axe(cote) + Vector3(cos(a2), 0, sin(a2)) * _rayon(a2, cote)
			if cote > 0.5:
				p1.y += _cassure(a1)
				p2.y += _cassure(a2)
			var points := [centre, p1, p2] if cote > 0.5 else [centre, p2, p1]
			for p in points:
				bouts.set_normal(normale)
				# UV : position sur le disque, de -1 à 1, pour dessiner les cernes.
				bouts.set_uv(Vector2(p.x - centre.x, p.z - centre.z) / (_rayon(0.0, cote) * 1.05))
				bouts.add_vertex(p)
	bouts.commit(maillage)
	maillage.surface_set_material(1, bois_coupe)
	return maillage


## Une branche cassée qui sort du tronc à « t », à l'angle « angle » : un petit cône
## tronqué penché vers le bout du tronc.
func _moignon(outil: SurfaceTool, t: float, angle: float, rayon: float, longueur: float) -> void:
	var depart := _axe(t) + Vector3(cos(angle), 0, sin(angle)) * (_rayon(angle, t) * 0.8)
	var direction := (Vector3(cos(angle), 0.45, sin(angle))).normalized()
	var x := direction.cross(Vector3.UP).normalized()
	var z := direction.cross(x).normalized()
	var cotes := 8
	var debut := _sommets
	for anneau in 3:
		var f := anneau / 2.0
		var r := rayon * lerpf(1.25, 0.6, f)
		var centre := depart + direction * longueur * f
		for k in cotes + 1:
			var a := TAU * k / cotes
			var bout := 0.0 if anneau < 2 else sin(a * 3.0) * 0.03
			outil.set_color(Color.WHITE)
			outil.set_uv(Vector2(float(k) / cotes, f * 0.5))
			outil.add_vertex(centre + (x * cos(a) + z * sin(a)) * r + direction * bout)
	for anneau in 2:
		for k in cotes:
			var i := debut + anneau * (cotes + 1) + k
			var j := i + cotes + 1
			outil.add_index(i)
			outil.add_index(i + 1)
			outil.add_index(j)
			outil.add_index(i + 1)
			outil.add_index(j + 1)
			outil.add_index(j)
	# Le bout cassé, fermé.
	var centre_bout := debut + 2 * (cotes + 1)
	outil.set_color(Color(0.8, 0.7, 0.55))
	outil.set_uv(Vector2(0.5, 0.5))
	outil.add_vertex(depart + direction * longueur * 1.04)
	var milieu := debut + 3 * (cotes + 1)
	_sommets = milieu + 1
	for k in cotes:
		outil.add_index(milieu)
		outil.add_index(centre_bout + k + 1)
		outil.add_index(centre_bout + k)


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
