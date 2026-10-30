extends Node3D
## Un survivant de Bruneval : sa tenue (Modular Character Outfits Fantasy), une tête et une
## coiffure, une petite activité qui le fait vivre (garder l'entrée, être assis au feu,
## porter de l'eau, tenir son étal, attendre bras croisés), et ses répliques : touche E à
## côté, une bulle de dialogue s'ouvre en bas de l'écran (voir interface.gd, parler).

@export var nom := ""
@export var tenue := "Male_Peasant"
@export var femme := false
## Coiffures (fichiers Hair_… du pack), vide pour aucune (capuche).
@export var coiffures: Array[String] = []
@export var teinte := Color(0.6, 0.6, 0.65)
@export var couleur_cheveux := Color(0.25, 0.22, 0.2)
## « garde » (torche), « assis », « porte_eau », « etal », « bras_croises », « balade »,
## « forge » (frappe l'enclume au marteau, avec des étincelles).
@export var activite := "bras_croises"
@export var repliques: Array[String] = []
## Pour « porte_eau » : l'autre bout de son aller-retour.
@export var aller_vers := Vector3.ZERO
## Pour « balade » : les endroits où il flâne, dans l'ordre (il va d'un point à son voisin).
@export var points_de_balade: Array[Vector3] = []
## Sa silhouette : « corpulence » élargit le corps (1,3 = costaud), « taille » le grandit.
@export var corpulence := 1.0
@export var taille := 1.0
## Un ventre rond (1 = normal, 1,3 = bedonnant).
@export var ventre := 1.0
## Ses petits gestes, joués de temps en temps (sa personnalité), par ex. « Interact ».
@export var gestes: Array[String] = []
## Pour « forge » : l'endroit où frappe le marteau (le dessus de l'enclume), où jaillissent
## les étincelles.
@export var point_de_frappe := Vector3.ZERO
@export var distance_interaction := 2.0
## Pour un marchand : sa boutique (« forgeron » ou « medecin », voir boutiques.gd) et son
## titre. Elle s'ouvre après la première conversation, puis directement avec E.
@export var boutique := ""
@export var titre_boutique := ""
## Un petit « ! » doré flotte au-dessus de sa tête : il a une quête à donner.
@export var quete := false

const DOSSIER := "res://assets/personnage/"
const OS_DE_LA_TETE := ["Head", "neck_01"]
const VITESSE_MARCHE := 1.3

static var _bibliotheques := {}

var parle := false
var _deja_parle := false
var _client: Node
var _icone_quete: Label3D
var _anim: AnimationPlayer
var _squelette: Skeleton3D
var _modele: Node3D
var _depart := Vector3.ZERO
var _cible := Vector3.ZERO
var _pause := 0.0
var _temps := 0.0
var _rng := RandomNumberGenerator.new()
var _point := 0
var _sens := 1
## Le temps qu'il reste au geste en cours (0 : pas de geste).
var _geste_restant := 0.0
## Le forgeron : son geste de frappe, le moment où le marteau touche l'enclume (mesuré
## sur l'animation), ses étincelles et l'éclair de lumière du choc.
const ANIM_FRAPPE := "Sword_Attack"
const MOMENT_DU_CHOC := 0.47
const MARTEAU := "res://assets/objets/Marteau.fbx"
## Le marteau dans la main : la même prise que l'épée du héros, réduit à 60 cm environ.
const MARTEAU_DANS_LA_MAIN := Transform3D(
	Vector3(-0.996105, -0.086398, 0.017613) * 0.16, Vector3(-0.005154, 0.256456, 0.966542) * 0.16,
	Vector3(-0.088024, 0.962687, -0.255902) * 0.16, Vector3(-0.035, 0.112, -0.005)) * Transform3D(Basis(), Vector3(0, -0.35, 0))
var _temps_frappe := 0.0
var _prochaine_frappe := 0.5
var _a_frappe := false
var _etincelles: CPUParticles3D
var _eclair: OmniLight3D
var _tete_du_marteau: MeshInstance3D


func _ready() -> void:
	add_to_group("interactif")
	_rng.seed = hash(nom)
	_depart = position
	_cible = aller_vers
	_construire()
	_anim.play(_animation_de_repos())
	_anim.seek(_rng.randf_range(0.0, 2.0), true)
	if quete:
		_icone_quete = Label3D.new()
		_icone_quete.text = "!"
		_icone_quete.font = load("res://assets/polices/Cinzel.ttf")
		_icone_quete.font_size = 64
		_icone_quete.pixel_size = 0.006
		_icone_quete.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_icone_quete.modulate = Color("f2c46b")
		_icone_quete.outline_modulate = Color("07091a")
		_icone_quete.outline_size = 12
		_icone_quete.position.y = 2.25
		add_child(_icone_quete)
	if activite == "balade" and not points_de_balade.is_empty():
		_point = _rng.randi_range(0, points_de_balade.size() - 1)
		_cible = points_de_balade[_point]
		_pause = _rng.randf_range(0.5, 3.0)
		_sens = 1 if _rng.randf() < 0.5 else -1
	# Ceux qui marchent n'ont pas de corps solide (le héros passe à côté sans être bloqué).
	if activite != "porte_eau" and activite != "balade":
		var forme := CapsuleShape3D.new()
		forme.radius = 0.35
		forme.height = 1.8
		var zone := CollisionShape3D.new()
		zone.shape = forme
		zone.position.y = 0.9
		var corps := StaticBody3D.new()
		corps.add_child(zone)
		add_child(corps)


func _process(delta: float) -> void:
	_temps += delta
	if _icone_quete:
		_icone_quete.position.y = 2.25 + sin(_temps * 2.2) * 0.06
	if parle:
		return
	match activite:
		"porte_eau":
			_marcher(delta)
		"balade":
			_marcher(delta)
		"forge":
			_forger(delta)
		_:
			_faire_des_gestes(delta)


## Le forgeron frappe le métal sur l'enclume : il lève le marteau, l'abat (étincelles et
## éclair de lumière au moment du choc), souffle un instant, et recommence.
func _forger(delta: float) -> void:
	_temps_frappe += delta
	if _anim.current_animation == ANIM_FRAPPE:
		if not _a_frappe and _anim.current_animation_position >= MOMENT_DU_CHOC:
			_a_frappe = true
			_etincelles.restart()
			_eclair.light_energy = 0.7
			create_tween().tween_property(_eclair, "light_energy", 0.0, 0.45).set_ease(Tween.EASE_OUT)
		return
	if _a_frappe:
		# Le geste vient de finir : une petite pause avant le coup suivant.
		_a_frappe = false
		_temps_frappe = 0.0
		_prochaine_frappe = _rng.randf_range(0.3, 1.1)
		_anim.play("Idle", 0.25)
	elif _temps_frappe >= _prochaine_frappe:
		_anim.play(ANIM_FRAPPE, 0.2)
		_temps_frappe = 0.0


## Élise va du puits à la médecin et revient ; ceux qui flânent vont de point en point.
## Une pause à chaque arrêt (avec parfois un petit geste).
func _marcher(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		_faire_des_gestes(delta)
		if _pause <= 0.0:
			_geste_restant = 0.0
			_anim.play(_animation_de_marche(), 0.3)
		return
	var vers := _cible - position
	vers.y = 0.0
	if vers.length() < 0.15:
		if activite == "balade":
			# Le point suivant, voisin ; parfois il fait demi-tour.
			if _rng.randf() < 0.3:
				_sens = -_sens
			_point = posmod(_point + _sens, points_de_balade.size())
			_cible = points_de_balade[_point]
			_pause = _rng.randf_range(2.0, 7.0)
		else:
			_cible = _depart if _cible == aller_vers else aller_vers
			_pause = _rng.randf_range(2.0, 4.0)
		_anim.play("Idle", 0.3)
		return
	position += vers.normalized() * min(_vitesse() * delta, vers.length())
	_modele.rotation.y = lerp_angle(_modele.rotation.y, atan2(vers.x, vers.z), 1.0 - exp(-6.0 * delta))


func _vitesse() -> float:
	return VITESSE_MARCHE * (0.85 if activite == "balade" else 1.0)


func _animation_de_marche() -> String:
	return "ual2/Walk_Carry" if activite == "porte_eau" else "Walk"


## De temps en temps, un petit geste qui lui ressemble, puis il reprend sa pose.
func _faire_des_gestes(delta: float) -> void:
	if _geste_restant > 0.0:
		_geste_restant -= delta
		if _geste_restant <= 0.0:
			_anim.play("Idle" if _pause > 0.0 else _animation_de_repos(), 0.4)
		return
	if gestes.is_empty() or _rng.randf() > delta * 0.1:
		return
	var geste: String = gestes[_rng.randi_range(0, gestes.size() - 1)]
	if not _anim.has_animation(geste):
		return
	_anim.play(geste, 0.35)
	var longueur := _anim.get_animation(geste).length
	_geste_restant = 3.5 if _anim.get_animation(geste).loop_mode != Animation.LOOP_NONE else maxf(longueur - 0.3, 0.8)


func _animation_de_repos() -> String:
	match activite:
		"garde":
			return "Idle_Torch"
		"assis":
			return "Sitting_Idle"
		"porte_eau":
			return "ual2/Walk_Carry"
		"bras_croises":
			return "ual2/Idle_FoldArms"
	return "Idle"


# --- Dialogue -------------------------------------------------------------------

func distance_pour_interagir(joueur: Node3D) -> float:
	var d := Vector2(joueur.global_position.x - global_position.x, joueur.global_position.z - global_position.z).length()
	return d if d < distance_interaction and not repliques.is_empty() else INF


func texte_interaction(_joueur: Node3D) -> String:
	if boutique != "" and _deja_parle:
		return "E : " + titre_boutique.to_lower()
	if nom.begins_with("Le "):
		return "E : parler au " + nom.substr(3)
	return "E : parler à " + nom


func interagir(joueur: Node3D) -> void:
	var interface := get_tree().get_first_node_in_group("interface")
	if interface == null:
		return
	_client = joueur
	if boutique != "" and _deja_parle:
		interface.ouvrir_boutique(titre_boutique, boutique, joueur)
		return
	parle = true
	# Il se tourne vers le héros (sauf assis) et parle avec les mains.
	if activite != "assis":
		var vers := joueur.global_position - global_position
		_modele.global_rotation.y = atan2(vers.x, vers.z)
	_anim.play("Sitting_Talking" if activite == "assis" else "Idle_Talking", 0.3)
	interface.parler(nom, repliques, self)


## Appelé par l'interface quand la conversation est finie.
func fin_de_dialogue() -> void:
	parle = false
	_anim.play(_animation_de_repos(), 0.4)
	_geste_restant = 0.0
	# Ceux qui marchaient attendent un instant, puis repartent.
	if activite == "balade" or activite == "porte_eau":
		_pause = maxf(_pause, 0.8)
		_anim.play("Idle", 0.4)
	_deja_parle = true
	if boutique != "" and is_instance_valid(_client):
		get_tree().get_first_node_in_group("interface").ouvrir_boutique(titre_boutique, boutique, _client)


# --- Construction -----------------------------------------------------------------

func _construire() -> void:
	_modele = (load(DOSSIER + tenue + ".gltf") as PackedScene).instantiate()
	add_child(_modele)
	_modele.scale = Vector3(corpulence, 1.0, corpulence) * taille
	_squelette = _modele.find_children("*", "Skeleton3D", true, false)[0]
	# La tête (et les yeux, les sourcils) du corps de base ; la tenue n'en a pas.
	var corps := (load(DOSSIER + ("Superhero_Female_FullBody" if femme else "Superhero_Male_FullBody") + ".gltf") as PackedScene).instantiate()
	for maillage in corps.find_children("*", "MeshInstance3D", true, false):
		if maillage.name.to_lower().begins_with("superhero"):
			_garder_seulement_la_tete(maillage)
		_deplacer_sur_le_corps(maillage)
	corps.free()
	# Les coiffures et barbes ne sont pas articulées : on les accroche à l'os de la tête,
	# sinon elles restent en l'air quand le corps bouge (assis, penché…).
	var tete := BoneAttachment3D.new()
	tete.bone_name = "Head"
	_squelette.add_child(tete)
	var repos_tete := _squelette.get_bone_global_rest(_squelette.find_bone("Head"))
	# Le squelette peut être décalé dans le modèle : on en tient compte.
	var place_squelette := Transform3D()
	var noeud: Node = _squelette
	while noeud and noeud != _modele:
		place_squelette = (noeud as Node3D).transform * place_squelette
		noeud = noeud.get_parent()
	repos_tete = place_squelette * repos_tete
	for coiffure in coiffures:
		var cheveux := (load(DOSSIER + coiffure + ".gltf") as PackedScene).instantiate()
		for maillage in cheveux.find_children("*", "MeshInstance3D", true, false):
			# Sa place dans le fichier de la coiffure (le fichier n'est pas dans la scène).
			var place: Transform3D = maillage.transform
			var parent := maillage.get_parent() as Node3D
			while parent and parent != cheveux:
				place = parent.transform * place
				parent = parent.get_parent() as Node3D
			maillage.get_parent().remove_child(maillage)
			maillage.owner = null
			tete.add_child(maillage)
			maillage.transform = repos_tete.affine_inverse() * place
			_teinter(maillage, couleur_cheveux)
		cheveux.free()
	for maillage in _modele.find_children("*", "MeshInstance3D", true, false):
		if maillage.get_surface_override_material_count() > 0 and maillage.get_surface_override_material(0) == null:
			if maillage.name == "Eyebrows":
				_teinter(maillage, couleur_cheveux)
			elif not maillage.name.to_lower().begins_with("superhero") and maillage.name != "Eyes":
				_teinter(maillage, teinte)
	_anim = AnimationPlayer.new()
	_modele.add_child(_anim)
	_anim.root_node = NodePath("..")
	_anim.add_animation_library("", _bibliotheque("UAL1_Standard.glb"))
	_anim.add_animation_library("ual2", _bibliotheque("UAL2_Standard.glb"))
	# Un ventre rond pour les costauds : le bas du torse gonfle, le haut reste normal.
	# (Les animations ne touchent pas à la taille des os : il suffit de le faire une fois.)
	if ventre != 1.0:
		var bas := _squelette.find_bone("spine_01")
		var haut := _squelette.find_bone("spine_03")
		_squelette.set_bone_pose_scale(bas, Vector3(ventre, 1.0, ventre))
		_squelette.set_bone_pose_scale(haut, Vector3(1.0 / ventre, 1.0, 1.0 / ventre))
	if activite == "forge":
		_preparer_la_forge()
	# La torche de Bran, dans sa main, avec sa lumière.
	if activite == "garde":
		var attache := BoneAttachment3D.new()
		attache.bone_name = "hand_l"
		_squelette.add_child(attache)
		var torche := Modeles.creer("Torch_Metal")
		torche.position = Vector3(0, 0.05, 0)
		attache.add_child(torche)
		var lumiere := OmniLight3D.new()
		lumiere.light_color = Color("e0823a")
		lumiere.light_energy = 1.4
		lumiere.omni_range = 6.0
		lumiere.position = Vector3(0, 0.6, 0)
		attache.add_child(lumiere)


## Le marteau (Hammer Pack, CC0) dans la main droite, couleur de fer ; les étincelles
## (de petits éclats orange qui retombent) et l'éclair de lumière, sur l'enclume.
func _preparer_la_forge() -> void:
	var attache := BoneAttachment3D.new()
	attache.bone_name = "hand_r"
	_squelette.add_child(attache)
	var marteau := (load(MARTEAU) as PackedScene).instantiate() as Node3D
	# Le fichier du marteau contient aussi la lampe (un « soleil ») et la caméra de la scène
	# Blender de son auteur : on les retire, sinon ce soleil tourne avec le bras à chaque
	# coup et tout l'écran du jeu flashe.
	for intrus in marteau.find_children("*", "Light3D", true, false) + marteau.find_children("*", "Camera3D", true, false):
		intrus.free()
	Modeles.teinter(marteau, Color(0.32, 0.3, 0.32))
	marteau.transform = MARTEAU_DANS_LA_MAIN
	attache.add_child(marteau)
	_tete_du_marteau = marteau.find_children("*", "MeshInstance3D", true, false)[0]
	_se_placer_a_l_enclume.call_deferred()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var eclat := QuadMesh.new()
	eclat.size = Vector2(0.035, 0.035)
	eclat.material = mat
	_etincelles = CPUParticles3D.new()
	_etincelles.mesh = eclat
	_etincelles.top_level = true
	_etincelles.emitting = false
	_etincelles.one_shot = true
	_etincelles.amount = 26
	_etincelles.lifetime = 0.7
	_etincelles.explosiveness = 0.95
	_etincelles.direction = Vector3.UP
	_etincelles.spread = 70.0
	_etincelles.initial_velocity_min = 1.5
	_etincelles.initial_velocity_max = 3.6
	_etincelles.gravity = Vector3(0, -7.0, 0)
	var couleurs := Gradient.new()
	couleurs.set_color(0, Color(1.0, 0.9, 0.55, 1.0))
	couleurs.set_color(1, Color(1.0, 0.35, 0.08, 0.0))
	_etincelles.color_ramp = couleurs
	add_child(_etincelles)
	_etincelles.global_position = point_de_frappe
	_eclair = OmniLight3D.new()
	_eclair.light_color = Color("ff9a45")
	_eclair.light_energy = 0.0
	_eclair.omni_range = 2.5
	_eclair.top_level = true
	add_child(_eclair)
	_eclair.global_position = point_de_frappe + Vector3.UP * 0.4


## Le coup part un peu de côté : on mesure où tombe la tête du marteau au moment du choc,
## puis le forgeron pivote et se place (toujours derrière l'enclume, du côté où il a été
## posé) pour qu'elle tombe pile dessus.
func _se_placer_a_l_enclume() -> void:
	_anim.play(ANIM_FRAPPE)
	_anim.seek(MOMENT_DU_CHOC, true)
	var main := _squelette.global_transform * _squelette.get_bone_global_pose(_squelette.find_bone("hand_r"))
	var boite := _tete_du_marteau.get_aabb()
	var tete := main * MARTEAU_DANS_LA_MAIN * (_tete_du_marteau.transform * (boite.position + Vector3(boite.size.x / 2.0, boite.size.y * 0.9, boite.size.z / 2.0)))
	var ecart := tete - global_position
	ecart.y = 0.0
	var vers_enclume := point_de_frappe - global_position
	vers_enclume.y = 0.0
	vers_enclume = vers_enclume.normalized()
	_modele.rotation.y += atan2(vers_enclume.x, vers_enclume.z) - atan2(ecart.x, ecart.z)
	global_position = Vector3(point_de_frappe.x, global_position.y, point_de_frappe.z) - vers_enclume * ecart.length()
	_anim.play("Idle")


## Les animations (Universal Animation Library), chargées une seule fois pour tous.
static func _bibliotheque(fichier: String) -> AnimationLibrary:
	if not _bibliotheques.has(fichier):
		var source := (load(DOSSIER + fichier) as PackedScene).instantiate()
		var lecteur := source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var biblio := lecteur.get_animation_library("")
		for nom_anim in ["Idle", "Idle_Torch", "Sitting_Idle", "Sitting_Talking", "Idle_Talking", "Walk_Carry", "Idle_FoldArms", "Walk"]:
			if biblio.has_animation(nom_anim):
				biblio.get_animation(nom_anim).loop_mode = Animation.LOOP_LINEAR
		_bibliotheques[fichier] = biblio
		source.free()
	return _bibliotheques[fichier]


func _deplacer_sur_le_corps(maillage: MeshInstance3D) -> void:
	maillage.get_parent().remove_child(maillage)
	maillage.owner = null
	_squelette.add_child(maillage)
	maillage.skeleton = NodePath("..")


func _teinter(maillage: MeshInstance3D, couleur: Color) -> void:
	for i in maillage.mesh.get_surface_count():
		var mat := maillage.mesh.surface_get_material(i) as StandardMaterial3D
		if mat:
			var copie := mat.duplicate() as StandardMaterial3D
			copie.albedo_color = mat.albedo_color * couleur
			maillage.set_surface_override_material(i, copie)


## Ne garde que les triangles du maillage qui bougent avec la tête ou le cou.
func _garder_seulement_la_tete(maillage: MeshInstance3D) -> void:
	var skin := maillage.skin
	var garder := {}
	for b in skin.get_bind_count():
		var nom_os := String(skin.get_bind_name(b))
		if nom_os.is_empty():
			nom_os = _squelette.get_bone_name(skin.get_bind_bone(b))
		if nom_os in OS_DE_LA_TETE:
			garder[b] = true
	var ancien := maillage.mesh
	var nouveau := ArrayMesh.new()
	for s in ancien.get_surface_count():
		var tableaux := ancien.surface_get_arrays(s)
		var os: PackedInt32Array = tableaux[Mesh.ARRAY_BONES]
		var poids: PackedFloat32Array = tableaux[Mesh.ARRAY_WEIGHTS]
		var sommets: int = (tableaux[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var par_sommet := os.size() / sommets
		var indices: PackedInt32Array = tableaux[Mesh.ARRAY_INDEX]
		var gardes := PackedInt32Array()
		for t in range(0, indices.size(), 3):
			var dans_la_tete := true
			for k in 3:
				var v := indices[t + k]
				var meilleur := 0
				for w in par_sommet:
					if poids[v * par_sommet + w] > poids[v * par_sommet + meilleur]:
						meilleur = w
				if not garder.has(os[v * par_sommet + meilleur]):
					dans_la_tete = false
					break
			if dans_la_tete:
				gardes.append(indices[t])
				gardes.append(indices[t + 1])
				gardes.append(indices[t + 2])
		if gardes.is_empty():
			continue
		tableaux[Mesh.ARRAY_INDEX] = gardes
		# Le corps féminin a des canaux de données en plus, inutiles ici et refusés à la copie.
		for canal in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
			tableaux[canal] = null
		var options := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if par_sommet == 8 else 0
		nouveau.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tableaux, [], {}, options)
		nouveau.surface_set_material(nouveau.get_surface_count() - 1, ancien.surface_get_material(s))
	maillage.mesh = nouveau
