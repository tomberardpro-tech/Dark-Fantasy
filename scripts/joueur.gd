extends CharacterBody3D
## Le héros : tenue « Paysan » de Quaternius, tête et cheveux longs du pack Universal
## Base Characters, animé avec les Universal Animation Library 1 et 2.
## ZQSD ou clic de souris pour marcher, Maj pour courir, Espace pour une roulade.
## R : sortir ou ranger l'épée. Épée sortie : clic gauche pour attaquer (combo de 3 coups).
## Il peut s'asseoir (voir tronc.gd) et se relève dès qu'on bouge.

@export var vitesse_marche := 4.0
@export var vitesse_course := 7.0
@export var vitesse_roulade := 7.0
## Durée d'une roulade, en secondes.
@export var duree_roulade := 0.6
## Le personnage commence-t-il assis sur le tronc ?
@export var assis_au_depart := true
## Réglages de la position assise : recul vers le tronc et hauteur (en mètres).
## Mesurés sur l'animation « Sitting_Idle » : le bassin y est à 0,54 m de haut et
## 0,33 m en arrière ; le tronc fait 0,46 m de haut, son milieu est à 0,65 m derrière.
@export var assise_recul := 0.3
@export var assise_hauteur := 0.04
## Teinte appliquée à la tenue pour coller à la palette sombre.
@export var teinte := Color(0.85, 0.85, 0.92)
## Couleur des cheveux et des sourcils (noirs).
@export var couleur_cheveux := Color(0.12, 0.11, 0.13)

const ANIMATIONS := "res://assets/personnage/UAL1_Standard.glb"
const ANIMATIONS_2 := "res://assets/personnage/UAL2_Standard.glb"
const CORPS := "res://assets/personnage/Superhero_Male_FullBody.gltf"
const CHEVEUX := "res://assets/personnage/Hair_Long.gltf"
const EN_BOUCLE := ["Idle", "Walk", "Jog_Fwd", "Sprint", "Sitting_Idle", "Sword_Idle"]
## Les os gardés pour la tête (le reste du corps de base est caché par la tenue).
const OS_DE_LA_TETE := ["Head", "neck_01"]

## Dégainer : on joue le début du lancer par-dessus l'épaule ; la main est derrière
## l'épaule à ce moment (mesuré), c'est là que l'épée passe du dos à la main.
const ANIM_DEGAINER := "ual2/OverhandThrow"
const MAIN_DANS_LE_DOS := 0.25
## Position de l'épée dans la main, mesurée sur l'animation « Sword_Idle » :
## la lame sort du côté du pouce et la poignée est au creux de la main.
const EPEE_DANS_LA_MAIN := Transform3D(
	Vector3(-0.996105, -0.086398, 0.017613), Vector3(-0.005154, 0.256456, 0.966542),
	Vector3(-0.088024, 0.962687, -0.255902), Vector3(-0.0092, 0.10505, -0.005))
## Les coups du combo, dans l'ordre, et leur retour en garde.
const COUPS := ["ual2/Sword_Regular_A", "ual2/Sword_Regular_B", "ual2/Sword_Regular_C"]
const RETOURS := ["ual2/Sword_Regular_A_Rec", "ual2/Sword_Regular_B_Rec", ""]

var est_assis := false
## L'objet sur lequel il est assis (un tronc près d'un feu), ou rien.
var siege: Node = null
## A-t-il trouvé la vieille épée ?
var a_epee := false
## L'épée est-elle dans sa main (prête à attaquer) ?
var epee_sortie := false

var _cible_clic: Variant = null
var _clic_maintenu := false
var _clic_avant := false
var _roulade_restante := 0.0
var _direction_roulade := Vector3.ZERO
var _attente_roulade := 0.0
var _anim: AnimationPlayer
var _squelette: Skeleton3D
var _epee_dos: Node3D
var _epee_main: Node3D
## Ce que fait le héros en ce moment : "" (rien de spécial), "degainer", "ranger", "attaque".
var _action := ""
## Le coup du combo en cours (0 = A, 1 = B, 2 = C) et s'il y a eu un clic pour enchaîner.
var _coup := 0
var _clic_en_attente := false

@onready var _visuel: Node3D = $Visuel
@onready var _modele: Node3D = $Visuel/Modele


func _ready() -> void:
	_squelette = _modele.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_preparer_animations()
	_ajouter_tete_et_cheveux()
	_teinter_tenue()
	if Sauvegarde.donnee("epee", false):
		prendre_epee()
	_jouer("Idle")


## Cherche ce qui est à portée (tronc, charrette…), affiche « E : … » et réagit à E.
func _process(_delta: float) -> void:
	var interface := get_tree().get_first_node_in_group("interface")
	var cible: Node = null
	var plus_proche := INF
	for objet in get_tree().get_nodes_in_group("interactif"):
		var d: float = objet.distance_pour_interagir(self)
		if d < plus_proche:
			plus_proche = d
			cible = objet
	if cible == null:
		if interface:
			interface.cacher()
		return
	if interface:
		interface.afficher(cible.texte_interaction(self))
	if Input.is_action_just_pressed("interagir"):
		cible.interagir(self)


## Le héros trouve la vieille épée : elle est rangée dans son dos.
func prendre_epee() -> void:
	if a_epee:
		return
	a_epee = true
	# L'épée du Fantasy Props MegaKit, un peu rouillée (teinte sombre), en deux exemplaires :
	# un dans le dos, un dans la main. On n'en montre qu'un à la fois.
	_epee_dos = _accrocher_epee("spine_03")
	# Dans le dos, en diagonale, la poignée au-dessus de l'épaule droite
	# (le héros regarde vers son +Z, le dos est vers -Z).
	var dans_le_dos := Transform3D(Basis(Vector3.BACK, PI + 0.6), Vector3(0.0, 1.1, -0.2))
	_epee_dos.transform = _squelette.get_bone_global_rest(_squelette.find_bone("spine_03")).affine_inverse() * dans_le_dos
	_epee_main = _accrocher_epee("hand_r")
	# La poignée (un peu sous l'origine du modèle) au creux de la main.
	_epee_main.transform = EPEE_DANS_LA_MAIN * Transform3D(Basis(), Vector3(0.0, 0.1, 0.0))
	_epee_main.visible = false


func _accrocher_epee(os: String) -> Node3D:
	var epee := Modeles.creer("Sword_Bronze", Modeles.OBJETS, Color(0.6, 0.6, 0.7))
	var attache := BoneAttachment3D.new()
	attache.bone_name = os
	_squelette.add_child(attache)
	attache.add_child(epee)
	return epee


func _physics_process(delta: float) -> void:
	_clic_maintenu = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var clic := _clic_maintenu and not _clic_avant
	_clic_avant = _clic_maintenu
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Sortir ou ranger l'épée.
	if Input.is_action_just_pressed("degainer") and a_epee and not est_assis and _action == "":
		if epee_sortie:
			_ranger_epee()
		else:
			_degainer()

	# Épée sortie : le clic attaque au lieu de déplacer.
	if epee_sortie and clic and not est_assis:
		_cliquer_pour_attaquer()

	var direction := _direction_clavier()
	if direction.length() > 0.01:
		_cible_clic = null
	elif _clic_maintenu and not epee_sortie:
		_cible_clic = _point_sous_la_souris()
	if _cible_clic != null:
		var vers: Vector3 = _cible_clic - global_position
		vers.y = 0.0
		if vers.length() < 0.15:
			_cible_clic = null
		else:
			direction = vers.normalized()

	_attente_roulade -= delta
	if Input.is_action_just_pressed("roulade") and _attente_roulade <= 0.0:
		_commencer_roulade(direction)

	if est_assis:
		if direction.length() > 0.01:
			se_relever()
		else:
			return

	if _roulade_restante > 0.0:
		_roulade_restante -= delta
		velocity.x = _direction_roulade.x * vitesse_roulade
		velocity.z = _direction_roulade.z * vitesse_roulade
	elif _action != "":
		# Pendant une attaque ou en dégainant, le héros reste sur place.
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var vitesse := vitesse_course if Input.is_action_pressed("courir") else vitesse_marche
		velocity.x = direction.x * vitesse
		velocity.z = direction.z * vitesse

	var au_sol := Vector3(velocity.x, 0.0, velocity.z)
	if au_sol.length() > 0.1:
		_regarder(au_sol, delta)
	move_and_slide()
	_choisir_animation(au_sol.length())


## Assoit le personnage à un endroit précis, tourné dans une direction.
## « tout_de_suite » : déjà assis (au lancement du jeu), sans l'animation pour s'asseoir.
func asseoir(point: Vector3, regard: Vector3, tout_de_suite := false, sur: Node = null) -> void:
	est_assis = true
	siege = sur
	_cible_clic = null
	velocity = Vector3.ZERO
	global_position = point
	_visuel.rotation.y = atan2(-regard.x, -regard.z)
	# On range l'épée sans animation avant de s'asseoir.
	_mettre_epee_dans_le_dos()
	_action = ""
	# Un peu en arrière et plus haut : il est posé sur le tronc.
	_modele.position = Vector3(0.0, assise_hauteur, assise_recul)
	if tout_de_suite:
		_anim.play("Sitting_Idle")
	else:
		_anim.play("Sitting_Enter", 0.2)
		_anim.queue("Sitting_Idle")


func se_relever() -> void:
	est_assis = false
	siege = null
	_modele.position = Vector3.ZERO
	_anim.clear_queue()
	_jouer("Idle")


func _choisir_animation(vitesse: float) -> void:
	if _action != "":
		return
	if _roulade_restante > 0.0:
		var longueur := _anim.get_animation("Roll").length
		_jouer("Roll", longueur / duree_roulade)
	elif vitesse > 5.5:
		_jouer("Sprint")
	elif vitesse > 0.5:
		_jouer("Jog_Fwd")
	else:
		_jouer("Sword_Idle" if epee_sortie else "Idle")


func _jouer(nom: String, vitesse := 1.0) -> void:
	if _anim.current_animation != nom:
		_anim.play(nom, 0.2, vitesse)


func _regarder(direction: Vector3, delta: float, tout_de_suite := false) -> void:
	var angle := atan2(-direction.x, -direction.z)
	if tout_de_suite:
		_visuel.rotation.y = angle
	else:
		_visuel.rotation.y = lerp_angle(_visuel.rotation.y, angle, 1.0 - exp(-12.0 * delta))


# --- L'épée ---------------------------------------------------------------

## Sortir l'épée : la main va la chercher derrière l'épaule, puis le héros se met en garde.
func _degainer() -> void:
	_action = "degainer"
	_anim.play_section(ANIM_DEGAINER, 0.0, MAIN_DANS_LE_DOS, 0.15)
	await get_tree().create_timer(MAIN_DANS_LE_DOS + 0.05).timeout
	if _action != "degainer":
		return
	_epee_dos.visible = false
	_epee_main.visible = true
	epee_sortie = true
	_anim.play("Sword_Idle", 0.35)
	await get_tree().create_timer(0.3).timeout
	if _action == "degainer":
		_action = ""


## Ranger l'épée : le même geste à l'envers, l'épée retourne dans le dos.
func _ranger_epee() -> void:
	_action = "ranger"
	_anim.play_section_backwards(ANIM_DEGAINER, 0.0, MAIN_DANS_LE_DOS, 0.2)
	await get_tree().create_timer(0.22).timeout
	if _action != "ranger":
		return
	_mettre_epee_dans_le_dos()
	await get_tree().create_timer(MAIN_DANS_LE_DOS).timeout
	if _action == "ranger":
		_action = ""


func _mettre_epee_dans_le_dos() -> void:
	epee_sortie = false
	if _epee_dos:
		_epee_dos.visible = true
		_epee_main.visible = false


## Un clic, épée sortie : premier coup, ou on enchaîne le coup suivant du combo.
func _cliquer_pour_attaquer() -> void:
	if _action == "":
		_tourner_vers_la_souris()
		_lancer_coup(0)
	elif _action == "attaque":
		var en_cours := _anim.current_animation
		# Pendant le retour en garde, un clic enchaîne tout de suite le coup suivant.
		if _coup < COUPS.size() - 1 and en_cours == RETOURS[_coup]:
			_tourner_vers_la_souris()
			_lancer_coup(_coup + 1)
		else:
			_clic_en_attente = true


func _lancer_coup(numero: int) -> void:
	_action = "attaque"
	_coup = numero
	_clic_en_attente = false
	_anim.play(COUPS[numero], 0.08)


## Appelé à la fin de chaque animation : enchaîne le combo ou revient en garde.
func _fin_animation(nom: StringName) -> void:
	if _action != "attaque":
		return
	if nom == COUPS[_coup]:
		if _clic_en_attente and _coup < COUPS.size() - 1:
			_tourner_vers_la_souris()
			_lancer_coup(_coup + 1)
		elif RETOURS[_coup] != "":
			_anim.play(RETOURS[_coup], 0.05)
		else:
			_fin_du_combo()
	elif nom == RETOURS[_coup]:
		_fin_du_combo()


func _fin_du_combo() -> void:
	_action = ""
	_coup = 0
	_clic_en_attente = false
	_anim.play("Sword_Idle", 0.25)


func _tourner_vers_la_souris() -> void:
	var point: Variant = _point_sous_la_souris()
	if point != null:
		var vers: Vector3 = point - global_position
		vers.y = 0.0
		if vers.length() > 0.2:
			_regarder(vers, 0.0, true)


# --- Déplacements ---------------------------------------------------------

## ZQSD converti en direction au sol, selon l'angle de la caméra (haut de l'écran = Z).
func _direction_clavier() -> Vector3:
	var entree := Input.get_vector("gauche", "droite", "reculer", "avancer")
	if entree.length() < 0.01:
		return Vector3.ZERO
	var camera := get_viewport().get_camera_3d()
	var avant := Vector3(0, 0, -1)
	var droite := Vector3(1, 0, 0)
	if camera:
		avant = -camera.global_basis.z
		avant.y = 0.0
		avant = avant.normalized()
		droite = camera.global_basis.x
		droite.y = 0.0
		droite = droite.normalized()
	return (droite * entree.x + avant * entree.y).limit_length(1.0)


func _commencer_roulade(direction: Vector3) -> void:
	if est_assis:
		se_relever()
	if _action == "attaque":
		_action = ""
	if direction.length() < 0.01:
		direction = -_visuel.global_basis.z
	_direction_roulade = Vector3(direction.x, 0.0, direction.z).normalized()
	_roulade_restante = duree_roulade
	_attente_roulade = duree_roulade + 0.25


## Le point du sol sous la souris, ou null.
func _point_sous_la_souris() -> Variant:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	# La souris est mesurée sur la fenêtre, puis ramenée à la taille du monde en pixels.
	var souris := get_tree().root.get_mouse_position()
	var conteneur := get_viewport().get_parent() as SubViewportContainer
	if conteneur:
		souris /= conteneur.stretch_shrink
	return Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(souris), camera.project_ray_normal(souris))


# --- Préparation du personnage --------------------------------------------

## Récupère les animations des Universal Animation Library 1 et 2 et les branche sur la
## tenue (même squelette, mêmes noms d'os). Celles du pack 2 commencent par « ual2/ ».
func _preparer_animations() -> void:
	_anim = AnimationPlayer.new()
	_anim.name = "Animations"
	_modele.add_child(_anim)
	_anim.root_node = NodePath("..")
	var bibliotheque := _bibliotheque(ANIMATIONS)
	for nom in EN_BOUCLE:
		bibliotheque.get_animation(nom).loop_mode = Animation.LOOP_LINEAR
	_anim.add_animation_library("", bibliotheque)
	_anim.add_animation_library("ual2", _bibliotheque(ANIMATIONS_2))
	_anim.animation_finished.connect(_fin_animation)


func _bibliotheque(fichier: String) -> AnimationLibrary:
	var source := (load(fichier) as PackedScene).instantiate()
	var lecteur := source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var bibliotheque := lecteur.get_animation_library("")
	source.free()
	return bibliotheque


## La tenue n'a pas de tête : on prend celle du corps de base (seulement la tête et le cou,
## le reste du corps est retiré), ses yeux et ses sourcils, et on ajoute les cheveux longs.
func _ajouter_tete_et_cheveux() -> void:
	var corps := (load(CORPS) as PackedScene).instantiate()
	for maillage in corps.find_children("*", "MeshInstance3D", true, false):
		if maillage.name == "SuperHero_Male":
			_garder_seulement_la_tete(maillage)
		_deplacer_sur_le_heros(maillage)
	corps.free()
	var cheveux := (load(CHEVEUX) as PackedScene).instantiate()
	for maillage in cheveux.find_children("*", "MeshInstance3D", true, false):
		_deplacer_sur_le_heros(maillage)
	cheveux.free()


func _deplacer_sur_le_heros(maillage: MeshInstance3D) -> void:
	maillage.get_parent().remove_child(maillage)
	maillage.owner = null
	_squelette.add_child(maillage)
	maillage.skeleton = NodePath("..")


## Ne garde que les triangles du maillage qui bougent avec la tête ou le cou.
func _garder_seulement_la_tete(maillage: MeshInstance3D) -> void:
	var skin := maillage.skin
	var garder := {}
	for b in skin.get_bind_count():
		var nom := String(skin.get_bind_name(b))
		if nom.is_empty():
			nom = _squelette.get_bone_name(skin.get_bind_bone(b))
		if nom in OS_DE_LA_TETE:
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
		var options := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if par_sommet == 8 else 0
		nouveau.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tableaux, [], {}, options)
		nouveau.surface_set_material(nouveau.get_surface_count() - 1, ancien.surface_get_material(s))
	maillage.mesh = nouveau


func _teinter_tenue() -> void:
	for maillage in _modele.find_children("*", "MeshInstance3D", true, false):
		# Cheveux et sourcils noirs (demande de Tom), le reste teinté vers la palette.
		var couleur := couleur_cheveux if maillage.name in ["Hair_Long", "Eyebrows"] else teinte
		for i in maillage.mesh.get_surface_count():
			var mat := maillage.mesh.surface_get_material(i) as StandardMaterial3D
			if mat:
				var copie := mat.duplicate() as StandardMaterial3D
				copie.albedo_color = mat.albedo_color * couleur
				maillage.set_surface_override_material(i, copie)
