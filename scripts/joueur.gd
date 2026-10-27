extends CharacterBody3D
## Le voyageur encapuchonné (tenue « Ranger » de Quaternius, animée avec la
## Universal Animation Library).
## ZQSD ou clic de souris pour marcher, Maj pour courir, Espace pour une roulade.
## Il peut s'asseoir (voir tronc.gd) et se relève dès qu'on bouge.

@export var vitesse_marche := 4.0
@export var vitesse_course := 7.0
@export var vitesse_roulade := 7.0
## Durée d'une roulade, en secondes.
@export var duree_roulade := 0.6
## Le personnage commence-t-il assis sur le tronc ?
@export var assis_au_depart := true
## Réglages de la position assise : recul vers le tronc et hauteur (en mètres).
@export var assise_recul := 0.35
@export var assise_hauteur := 0.1
## Teinte appliquée à la tenue pour coller à la palette sombre.
@export var teinte := Color(0.7, 0.7, 0.78)

const ANIMATIONS := "res://assets/personnage/UAL1_Standard.glb"
const EN_BOUCLE := ["Idle", "Walk", "Jog_Fwd", "Sprint", "Sitting_Idle"]

var est_assis := false

var _cible_clic: Variant = null
var _clic_maintenu := false
var _roulade_restante := 0.0
var _direction_roulade := Vector3.ZERO
var _attente_roulade := 0.0
var _anim: AnimationPlayer

@onready var _visuel: Node3D = $Visuel
@onready var _modele: Node3D = $Visuel/Modele


func _ready() -> void:
	_preparer_animations()
	_teinter_tenue()
	_ajouter_visage_dans_l_ombre()
	_jouer("Idle")


func _physics_process(delta: float) -> void:
	_clic_maintenu = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := _direction_clavier()
	if direction.length() > 0.01:
		_cible_clic = null
	elif _clic_maintenu:
		_viser_la_souris()
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
	else:
		var vitesse := vitesse_course if Input.is_action_pressed("courir") else vitesse_marche
		velocity.x = direction.x * vitesse
		velocity.z = direction.z * vitesse

	var au_sol := Vector3(velocity.x, 0.0, velocity.z)
	if au_sol.length() > 0.1:
		var angle := atan2(-au_sol.x, -au_sol.z)
		_visuel.rotation.y = lerp_angle(_visuel.rotation.y, angle, 1.0 - exp(-12.0 * delta))
	move_and_slide()
	_choisir_animation(au_sol.length())


## Assoit le personnage à un endroit précis, tourné dans une direction.
## « tout_de_suite » : déjà assis (au lancement du jeu), sans l'animation pour s'asseoir.
func asseoir(point: Vector3, regard: Vector3, tout_de_suite := false) -> void:
	est_assis = true
	_cible_clic = null
	velocity = Vector3.ZERO
	global_position = point
	_visuel.rotation.y = atan2(-regard.x, -regard.z)
	# Un peu en arrière et plus haut : il est posé sur le tronc.
	_modele.position = Vector3(0.0, assise_hauteur, assise_recul)
	if tout_de_suite:
		_anim.play("Sitting_Idle")
	else:
		_anim.play("Sitting_Enter", 0.2)
		_anim.queue("Sitting_Idle")


func se_relever() -> void:
	est_assis = false
	_modele.position = Vector3.ZERO
	_anim.clear_queue()
	_jouer("Idle")


func _choisir_animation(vitesse: float) -> void:
	if _roulade_restante > 0.0:
		var longueur := _anim.get_animation("Roll").length
		_jouer("Roll", longueur / duree_roulade)
	elif vitesse > 5.5:
		_jouer("Sprint")
	elif vitesse > 0.5:
		_jouer("Jog_Fwd")
	else:
		_jouer("Idle")


func _jouer(nom: String, vitesse := 1.0) -> void:
	if _anim.current_animation != nom:
		_anim.play(nom, 0.2, vitesse)


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
	if direction.length() < 0.01:
		direction = -_visuel.global_basis.z
	_direction_roulade = Vector3(direction.x, 0.0, direction.z).normalized()
	_roulade_restante = duree_roulade
	_attente_roulade = duree_roulade + 0.25


## Le point du sol sous la souris devient la destination.
func _viser_la_souris() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	# La souris est mesurée sur la fenêtre, puis ramenée à la taille du monde en pixels.
	var souris := get_tree().root.get_mouse_position()
	var conteneur := get_viewport().get_parent() as SubViewportContainer
	if conteneur:
		souris /= conteneur.stretch_shrink
	var point: Variant = Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(souris), camera.project_ray_normal(souris))
	if point != null:
		_cible_clic = point


## Récupère les animations de la Universal Animation Library et les branche sur la tenue
## (même squelette, mêmes noms d'os).
func _preparer_animations() -> void:
	var source := (load(ANIMATIONS) as PackedScene).instantiate()
	var lecteur := source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var bibliotheque := lecteur.get_animation_library("")
	source.free()
	for nom in EN_BOUCLE:
		bibliotheque.get_animation(nom).loop_mode = Animation.LOOP_LINEAR
	_anim = AnimationPlayer.new()
	_anim.name = "Animations"
	_modele.add_child(_anim)
	_anim.root_node = NodePath("..")
	_anim.add_animation_library("", bibliotheque)


func _teinter_tenue() -> void:
	for maillage in _modele.find_children("*", "MeshInstance3D", true, false):
		for i in maillage.mesh.get_surface_count():
			var mat := maillage.mesh.surface_get_material(i) as StandardMaterial3D
			if mat:
				var copie := mat.duplicate() as StandardMaterial3D
				copie.albedo_color = mat.albedo_color * teinte
				maillage.set_surface_override_material(i, copie)


## La tenue n'a pas de visage : on met une ombre sous la capuche.
func _ajouter_visage_dans_l_ombre() -> void:
	var squelette := _modele.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var os_tete := -1
	for i in squelette.get_bone_count():
		if squelette.get_bone_name(i).to_lower() == "head":
			os_tete = i
	if os_tete < 0:
		return
	var attache := BoneAttachment3D.new()
	attache.bone_name = squelette.get_bone_name(os_tete)
	squelette.add_child(attache)
	var forme := SphereMesh.new()
	forme.radius = 0.11
	forme.height = 0.24
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("07091a")
	mat.roughness = 1.0
	var ombre := MeshInstance3D.new()
	ombre.mesh = forme
	ombre.material_override = mat
	ombre.position = Vector3(0.0, 0.1, 0.02)
	attache.add_child(ombre)
