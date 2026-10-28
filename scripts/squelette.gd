extends CharacterBody3D
## Un squelette ennemi (KayKit Skeletons, animé avec les KayKit Character Animations).
## Il dort allongé au sol ; quand le héros approche, il se relève, le poursuit et frappe.
## Il encaisse les coups (petit recul) et s'effondre quand il n'a plus de vie.
## Si le héros meurt, il retourne dormir à sa place.

@export var modele := "Skeleton_Minion"
@export var arme := "Skeleton_Blade"
@export var vie_max := 30.0
@export var vitesse := 3.4
@export var degats := 12.0
## Distance à laquelle il se réveille quand le héros approche.
@export var distance_reveil := 13.0
## Distance à laquelle il peut frapper.
@export var portee := 1.7
## Taille du squelette (en mètres).
@export var taille := 1.75

const DOSSIER := "res://assets/ennemis/"
const TEINTE := Color(0.62, 0.62, 0.7)
const ATTAQUE := "combat/Melee_1H_Attack_Chop"
## Moment où le coup du squelette touche, dans son animation d'attaque (en secondes).
const MOMENT_DU_COUP := 0.55

## « dort », « reveil », « poursuite », « attaque », « touche », « mort ».
var etat := "dort"
var vie := 30.0
var _anim: AnimationPlayer
var _depart := Transform3D()
var _temps_etat := 0.0
var _a_frappe := false
var _recul := Vector3.ZERO
var _visuel: Node3D
var _forme: CollisionShape3D


func _ready() -> void:
	add_to_group("ennemi")
	_depart = global_transform
	vie = vie_max
	_construire()
	_dormir()


func _physics_process(delta: float) -> void:
	_temps_etat += delta
	if not is_on_floor():
		velocity += get_gravity() * delta
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	var vers := Vector3.ZERO
	if joueur:
		vers = joueur.global_position - global_position
		vers.y = 0.0
	var direction := Vector3.ZERO
	match etat:
		"dort":
			if joueur and joueur.est_vivant() and vers.length() < distance_reveil:
				_changer("reveil")
				_jouer("special/Skeletons_Awaken_Floor", 0.1)
		"reveil":
			if _temps_etat > _anim.get_animation("special/Skeletons_Awaken_Floor").length - 0.2:
				_changer("poursuite")
		"poursuite":
			if joueur == null or not joueur.est_vivant():
				_jouer("special/Skeletons_Idle")
			elif vers.length() > portee:
				direction = vers.normalized()
				_jouer("deplacement/Running_A")
			else:
				_changer("attaque")
				_a_frappe = false
				_tourner(vers, 1.0, true)
				_jouer(ATTAQUE, 0.1)
		"attaque":
			if vers.length() > 0.1:
				_tourner(vers, delta * 0.5)
			if not _a_frappe and _temps_etat >= MOMENT_DU_COUP:
				_a_frappe = true
				# Les modèles KayKit regardent vers leur +Z.
				var devant := _visuel.global_basis.z
				if joueur and vers.length() < portee + 0.6 and devant.dot(vers.normalized()) > 0.2:
					joueur.prendre_coup(degats, global_position)
			if _temps_etat >= _anim.get_animation(ATTAQUE).length + 0.35:
				_changer("poursuite")
		"touche":
			if _temps_etat >= 0.5:
				_changer("poursuite")
	velocity.x = direction.x * vitesse + _recul.x
	velocity.z = direction.z * vitesse + _recul.z
	_recul = _recul.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))
	if direction.length() > 0.01:
		_tourner(direction, delta)
	move_and_slide()


func est_vivant() -> bool:
	return etat != "mort" and etat != "dort"


## Le héros le frappe.
func prendre_coup(montant: float, depuis: Vector3) -> void:
	if not est_vivant():
		return
	vie -= montant
	var recul := global_position - depuis
	recul.y = 0.0
	_recul = recul.normalized() * 5.0
	if vie <= 0.0:
		_changer("mort")
		_jouer("special/Skeletons_Death", 0.05)
		# Il ne gêne plus le passage une fois à terre.
		_forme.disabled = true
	else:
		_changer("touche")
		_jouer("general/Hit_A", 0.05)


## Le héros est mort : le squelette retourne dormir à sa place, avec toute sa vie.
func reinitialiser() -> void:
	global_transform = _depart
	reset_physics_interpolation()
	vie = vie_max
	_forme.disabled = false
	_dormir()


func _dormir() -> void:
	_changer("dort")
	_jouer("special/Skeletons_Inactive_Floor_Pose", 0.0)


func _changer(nouvel_etat: String) -> void:
	etat = nouvel_etat
	_temps_etat = 0.0


func _jouer(nom: String, transition := 0.2) -> void:
	if _anim.current_animation != nom:
		_anim.play(nom, transition)


func _tourner(direction: Vector3, delta: float, tout_de_suite := false) -> void:
	# Les modèles KayKit regardent vers leur +Z.
	var angle := atan2(direction.x, direction.z)
	if tout_de_suite:
		_visuel.rotation.y = angle
	else:
		_visuel.rotation.y = lerp_angle(_visuel.rotation.y, angle, 1.0 - exp(-10.0 * delta))


func _construire() -> void:
	_visuel = Node3D.new()
	add_child(_visuel)
	var corps := (load(DOSSIER + modele + ".glb") as PackedScene).instantiate() as Node3D
	_visuel.add_child(corps)
	Modeles.teinter(corps, TEINTE)
	# Mise à la bonne taille : les KayKit sont plus petits que le héros.
	var hauteur := 0.0
	for m in corps.find_children("*", "MeshInstance3D", true, false):
		hauteur = max(hauteur, (m as MeshInstance3D).get_aabb().end.y)
	if hauteur > 0.0:
		corps.scale = Vector3.ONE * (taille / hauteur)
	# Son arme dans la main droite.
	var squelette := corps.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var attache := BoneAttachment3D.new()
	attache.bone_name = "handslot.r"
	squelette.add_child(attache)
	var objet := (load(DOSSIER + arme + ".gltf") as PackedScene).instantiate() as Node3D
	Modeles.teinter(objet, TEINTE)
	attache.add_child(objet)
	# Ses animations : générales, déplacements, combat et spéciales squelette.
	_anim = AnimationPlayer.new()
	corps.add_child(_anim)
	_anim.root_node = NodePath("..")
	for bibli in [["general", "Rig_Medium_General"], ["deplacement", "Rig_Medium_MovementBasic"],
			["combat", "Rig_Medium_CombatMelee"], ["special", "Rig_Medium_Special"]]:
		var source := (load(DOSSIER + bibli[1] + ".glb") as PackedScene).instantiate()
		var lecteur := source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		_anim.add_animation_library(bibli[0], lecteur.get_animation_library(""))
		source.free()
	for boucle in ["deplacement/Running_A", "special/Skeletons_Idle"]:
		_anim.get_animation(boucle).loop_mode = Animation.LOOP_LINEAR
	_forme = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = taille
	_forme.shape = capsule
	_forme.position.y = taille / 2.0
	add_child(_forme)
