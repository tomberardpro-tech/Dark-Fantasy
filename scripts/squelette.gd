extends CharacterBody3D
## Un squelette ennemi, fabriqué os par os sur le MÊME squelette d'animation que le héros
## (65 os Quaternius) : il a sa taille et utilise les mêmes animations (Universal Animation
## Library 1 et 2). Os fins, cage thoracique, crâne aux orbites rougeoyantes (la malédiction),
## épée rouillée à la main.
## Il dort allongé au bord du chemin ; quand le héros approche, il se relève, le poursuit et
## frappe. Touché, il recule ; à zéro, il s'effondre en tas d'os.
## Si le héros meurt, il se reconstitue et retourne dormir à sa place.

@export var vie_max := 50.0
@export var vitesse := 3.4
@export var degats := 14.0
## Distance à laquelle il se réveille quand le héros approche.
@export var distance_reveil := 13.0
## Distance à laquelle il peut frapper.
@export var portee := 1.8
## Pause entre deux attaques (en secondes) : le moment pour le frapper ou esquiver.
@export var pause_entre_attaques := 0.7

const CORPS := "res://assets/personnage/Male_Peasant.gltf"
const ANIMATIONS := "res://assets/personnage/UAL1_Standard.glb"
const ANIMATIONS_2 := "res://assets/personnage/UAL2_Standard.glb"
const COULEUR_OS := Color(0.5, 0.47, 0.41)
const COULEUR_YEUX := Color("b0303a")
const SE_RELEVER := "ual2/LayToIdle"
const ATTAQUE := "Sword_Attack"
## Moment où le coup du squelette touche, en part de son animation d'attaque.
const MOMENT_DU_COUP := 0.45
## Les os qu'on ne dessine pas (doigts : trop petits pour se voir).
const OS_IGNORES := ["index", "middle", "pinky", "ring", "thumb", "leaf"]

## « dort », « reveil », « poursuite », « attaque », « touche », « mort ».
var etat := "dort"
var vie := 50.0
var _anim: AnimationPlayer
var _depart := Transform3D()
var _temps_etat := 0.0
var _a_frappe := false
var _recul := Vector3.ZERO
var _visuel: Node3D
var _squelette: Skeleton3D
var _forme: CollisionShape3D
var _mat_os: StandardMaterial3D
var _morceaux: Array[Node3D] = []
## Le temps avant le prochain cliquetis de pas.
var _prochain_pas := 0.0
## Enterré : de combien le corps est sous la terre, sa hauteur normale, et le trou laissé.
const PROFONDEUR := 1.8
var _hauteur_visuel := 0.0
var _trou: Node3D


func _ready() -> void:
	add_to_group("ennemi")
	_depart = global_transform
	vie = vie_max
	_construire()
	_hauteur_visuel = _visuel.position.y
	_dormir()


func _physics_process(delta: float) -> void:
	_temps_etat += delta
	# Enterré, il ne bouge pas (et ne tombe pas : il n'a plus de corps solide).
	if not is_on_floor() and etat != "dort":
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
				_tourner(vers, 1.0, true)
				_anim.play(SE_RELEVER, 0.0)
				_sortir_de_terre()
				Sons.serie("os_cliquetis", self, 7, 1.0)
				Sons.jouer_apres(0.5, "rale", self)
		"reveil":
			if _temps_etat > _anim.get_animation(SE_RELEVER).length - 0.15:
				_changer("poursuite")
		"poursuite":
			if joueur == null or not joueur.est_vivant():
				_jouer("Sword_Idle")
			elif vers.length() > portee:
				direction = vers.normalized()
				_jouer("Jog_Fwd")
			elif _temps_etat > pause_entre_attaques:
				_changer("attaque")
				_a_frappe = false
				_tourner(vers, 1.0, true)
				_anim.play(ATTAQUE, 0.1)
				Sons.jouer_apres(_anim.get_animation(ATTAQUE).length * MOMENT_DU_COUP - 0.15, "souffle_epee", self, 0.0, 0.8)
				if randf() < 0.35:
					Sons.jouer("rale", self, -3.0)
			else:
				_tourner(vers, delta)
				_jouer("Sword_Idle")
		"attaque":
			var longueur := _anim.get_animation(ATTAQUE).length
			if not _a_frappe and _temps_etat >= longueur * MOMENT_DU_COUP:
				_a_frappe = true
				# Le modèle regarde vers son +Z.
				var devant := _visuel.global_basis.z
				if joueur and vers.length() < portee + 0.5 and devant.dot(vers.normalized()) > 0.2:
					joueur.prendre_coup(degats, global_position)
			if _temps_etat >= longueur:
				_changer("poursuite")
		"touche":
			if _temps_etat >= 0.45:
				_changer("poursuite")
	velocity.x = direction.x * vitesse + _recul.x
	velocity.z = direction.z * vitesse + _recul.z
	_recul = _recul.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))
	if direction.length() > 0.01:
		_tourner(direction, delta)
		# Les os qui cliquettent à chaque foulée.
		_prochain_pas -= delta
		if _prochain_pas <= 0.0:
			_prochain_pas = 0.3
			Sons.jouer("os_cliquetis", self, -3.0)
	if etat != "dort":
		move_and_slide()


func est_vivant() -> bool:
	return etat != "mort" and etat != "dort"


## Le héros le frappe : il recule, affiche les dégâts, et s'effondre s'il n'a plus de vie.
func prendre_coup(montant: float, depuis: Vector3, force_recul := 5.0) -> void:
	if not est_vivant():
		return
	vie -= montant
	_afficher_degats(montant)
	var recul := global_position - depuis
	recul.y = 0.0
	_recul = recul.normalized() * force_recul
	if vie <= 0.0:
		_s_effondrer(recul.normalized())
	elif etat != "attaque":
		_changer("touche")
		_anim.play("Hit_Chest", 0.05)


## Le héros est mort : le squelette se reconstitue et retourne dormir à sa place.
func reinitialiser() -> void:
	for morceau in _morceaux:
		if is_instance_valid(morceau):
			morceau.queue_free()
	_morceaux.clear()
	global_transform = _depart
	reset_physics_interpolation()
	vie = vie_max
	_forme.disabled = false
	_visuel.visible = true
	_dormir()


func _dormir() -> void:
	_changer("dort")
	# Couché sous la terre : la première image de l'animation « allongé → debout ».
	_anim.play(SE_RELEVER, 0.0)
	_anim.seek(0.0, true)
	_anim.pause()
	# Enterré : on ne le voit pas, on ne le touche pas.
	_visuel.position.y = _hauteur_visuel - PROFONDEUR
	_forme.disabled = true
	if is_instance_valid(_trou):
		_trou.queue_free()


## Il sort de terre : le corps remonte en se relevant, dans une gerbe de terre, avec un
## grondement sourd ; un trou de terre retournée reste à sa place.
func _sortir_de_terre() -> void:
	_forme.disabled = false
	var duree := _anim.get_animation(SE_RELEVER).length * 0.8
	var anim := create_tween()
	anim.tween_property(_visuel, "position:y", _hauteur_visuel, duree).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	Sons.jouer("impact_sol", global_position, -6.0, 0.6)
	Sons.serie("pas_terre", global_position, 6, duree, 4.0)
	# Le trou : un disque de terre sombre, un peu bombé.
	var terre := StandardMaterial3D.new()
	terre.albedo_color = Color("221a14")
	terre.roughness = 1.0
	var disque := CylinderMesh.new()
	disque.top_radius = 0.55
	disque.bottom_radius = 0.75
	disque.height = 0.08
	disque.radial_segments = 12
	var trou := MeshInstance3D.new()
	trou.mesh = disque
	trou.material_override = terre
	trou.top_level = true
	add_child(trou)
	trou.global_position = global_position + Vector3(0, 0.02, 0)
	_trou = trou
	# La gerbe de terre : des mottes qui jaillissent et retombent.
	var motte := BoxMesh.new()
	motte.size = Vector3.ONE * 0.07
	motte.material = terre
	var gerbe := CPUParticles3D.new()
	gerbe.mesh = motte
	gerbe.amount = 36
	gerbe.lifetime = 1.2
	gerbe.one_shot = true
	gerbe.explosiveness = 0.75
	gerbe.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	gerbe.emission_sphere_radius = 0.35
	gerbe.direction = Vector3.UP
	gerbe.spread = 40.0
	gerbe.initial_velocity_min = 2.0
	gerbe.initial_velocity_max = 4.0
	gerbe.angular_velocity_min = -300.0
	gerbe.angular_velocity_max = 300.0
	gerbe.scale_amount_min = 0.6
	gerbe.scale_amount_max = 1.6
	gerbe.top_level = true
	gerbe.emitting = true
	add_child(gerbe)
	gerbe.global_position = global_position + Vector3(0, 0.1, 0)
	get_tree().create_timer(2.0).timeout.connect(gerbe.queue_free)


func _changer(nouvel_etat: String) -> void:
	etat = nouvel_etat
	_temps_etat = 0.0


func _jouer(nom: String) -> void:
	if _anim.current_animation != nom or not _anim.is_playing():
		_anim.play(nom, 0.2)


func _tourner(direction: Vector3, delta: float, tout_de_suite := false) -> void:
	if direction.length() < 0.01:
		return
	var angle := atan2(direction.x, direction.z)
	if tout_de_suite:
		_visuel.rotation.y = angle
	else:
		_visuel.rotation.y = lerp_angle(_visuel.rotation.y, angle, 1.0 - exp(-10.0 * delta))


## Les chiffres des dégâts montent au-dessus de lui puis s'effacent.
func _afficher_degats(montant: float) -> void:
	var chiffre := Label3D.new()
	chiffre.text = str(int(round(montant)))
	chiffre.font = load("res://assets/polices/Cinzel.ttf")
	chiffre.font_size = 64
	chiffre.pixel_size = 0.006
	chiffre.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	chiffre.no_depth_test = true
	chiffre.modulate = Color("f0ad55")
	chiffre.outline_modulate = Color("07091a")
	chiffre.outline_size = 10
	chiffre.top_level = true
	add_child(chiffre)
	chiffre.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 2.1, 0)
	var anim := create_tween().set_parallel()
	anim.tween_property(chiffre, "global_position:y", chiffre.global_position.y + 0.8, 0.8).set_ease(Tween.EASE_OUT)
	anim.tween_property(chiffre, "modulate:a", 0.0, 0.8).set_delay(0.3)
	anim.chain().tween_callback(chiffre.queue_free)


## Le squelette lâche quelques pièces d'or (de 6 à 12 en tout), à ramasser en passant dessus.
func _lacher_de_l_or() -> void:
	var total := randi_range(6, 12)
	var nombre := randi_range(3, 5)
	for i in nombre:
		var piece := Node3D.new()
		piece.set_script(load("res://scripts/piece_or.gd"))
		piece.valeur = floori(float(total) / nombre) +(1 if i < total % nombre else 0)
		get_parent().add_child(piece)
		piece.global_position = global_position + Vector3.UP * 0.6


## Plus de vie : chaque os se détache et tombe au sol, puis le tas disparaît.
func _s_effondrer(direction: Vector3) -> void:
	_changer("mort")
	# Les os qui tombent et rebondissent sur le sol.
	Sons.serie("os_choc", global_position, 6, 0.8)
	Sons.serie("os_cliquetis", global_position, 9, 1.1)
	Sons.jouer("chute", global_position, -4.0, 1.3)
	_forme.disabled = true
	for os in _visuel.find_children("*", "MeshInstance3D", true, false):
		var piece := RigidBody3D.new()
		# Les os tombent sur le sol, mais le héros passe à travers.
		piece.collision_layer = 2
		piece.collision_mask = 1
		var forme := CollisionShape3D.new()
		var boite := BoxShape3D.new()
		boite.size = ((os as MeshInstance3D).get_aabb().size * os.global_basis.get_scale()).max(Vector3.ONE * 0.04)
		forme.shape = boite
		piece.add_child(forme)
		var copie := MeshInstance3D.new()
		copie.mesh = (os as MeshInstance3D).mesh
		copie.material_override = (os as MeshInstance3D).material_override
		piece.add_child(copie)
		get_parent().add_child(piece)
		piece.global_transform = os.global_transform.orthonormalized()
		copie.scale = os.global_basis.get_scale()
		piece.apply_central_impulse((direction * 0.8 + Vector3(randf_range(-0.6, 0.6), randf_range(0.2, 1.2), randf_range(-0.6, 0.6))) * 0.25)
		_morceaux.append(piece)
	_visuel.visible = false
	_lacher_de_l_or()
	await get_tree().create_timer(12.0).timeout
	if etat == "mort":
		for morceau in _morceaux:
			if is_instance_valid(morceau):
				var anim := morceau.create_tween()
				anim.tween_property(morceau, "scale", Vector3.ONE * 0.01, 1.5)
				anim.tween_callback(morceau.queue_free)


# --- Fabrication du squelette ----------------------------------------------

func _construire() -> void:
	_visuel = Node3D.new()
	add_child(_visuel)
	var corps := (load(CORPS) as PackedScene).instantiate() as Node3D
	_visuel.add_child(corps)
	# On ne garde que l'ossature d'animation : les vêtements disparaissent.
	for m in corps.find_children("*", "MeshInstance3D", true, false):
		m.queue_free()
	_squelette = corps.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_mat_os = StandardMaterial3D.new()
	_mat_os.albedo_color = COULEUR_OS
	_mat_os.roughness = 0.9
	_poser_les_os()
	_poser_le_crane()
	_poser_l_epee()
	_preparer_animations(corps)
	_forme = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	_forme.shape = capsule
	_forme.position.y = 0.9
	add_child(_forme)


## Un os fin entre chaque articulation et la suivante, et une petite boule à chaque jointure.
func _poser_les_os() -> void:
	for i in _squelette.get_bone_count():
		var parent := _squelette.get_bone_parent(i)
		var nom := _squelette.get_bone_name(i)
		if parent <= 0 or OS_IGNORES.any(func(m): return nom.contains(m)):
			continue
		var a := _squelette.get_bone_global_rest(parent).origin
		var b := _squelette.get_bone_global_rest(i).origin
		if a.distance_to(b) < 0.03:
			continue
		var epaisseur := _epaisseur(_squelette.get_bone_name(parent))
		var forme := CylinderMesh.new()
		forme.top_radius = epaisseur * 0.8
		forme.bottom_radius = epaisseur
		forme.height = a.distance_to(b)
		forme.radial_segments = 6
		forme.rings = 1
		var direction := (b - a).normalized()
		var cote := direction.cross(Vector3.FORWARD if abs(direction.y) > 0.9 else Vector3.UP).normalized()
		var base := Basis(cote, direction, cote.cross(direction)).orthonormalized()
		_attacher(parent, forme, Transform3D(base, (a + b) / 2.0))
		var jointure := SphereMesh.new()
		jointure.radius = epaisseur * 1.35
		jointure.height = epaisseur * 2.7
		jointure.radial_segments = 6
		jointure.rings = 3
		_attacher(i, jointure, Transform3D(Basis(), b))
	# La cage thoracique : des côtes en anneaux aplatis autour du haut de la colonne.
	var dos := _squelette.find_bone("spine_03")
	var milieu := _squelette.find_bone("spine_02")
	for k in 5:
		var os := dos if k < 3 else milieu
		var centre := _squelette.get_bone_global_rest(os).origin
		var cote := TorusMesh.new()
		cote.inner_radius = 0.105 - k * 0.006
		cote.outer_radius = cote.inner_radius + 0.022
		cote.rings = 14
		cote.ring_segments = 4
		_attacher(os, cote, Transform3D(Basis().scaled(Vector3(1.0, 0.6, 0.75)), centre + Vector3(0, 0.1 - k * 0.07, 0.04)))
	# Le bassin.
	var bassin := TorusMesh.new()
	bassin.inner_radius = 0.09
	bassin.outer_radius = 0.13
	bassin.rings = 12
	bassin.ring_segments = 4
	var pelvis := _squelette.find_bone("pelvis")
	_attacher(pelvis, bassin, Transform3D(Basis().scaled(Vector3(1.0, 0.7, 0.8)), _squelette.get_bone_global_rest(pelvis).origin))


func _epaisseur(nom: String) -> float:
	if nom.begins_with("thigh") or nom.begins_with("calf"):
		return 0.032
	if nom.begins_with("spine") or nom == "pelvis":
		return 0.03
	if nom.begins_with("upperarm") or nom.begins_with("lowerarm"):
		return 0.025
	return 0.02


## Le crâne, sa mâchoire et ses orbites où rougeoie la malédiction.
func _poser_le_crane() -> void:
	var tete := _squelette.find_bone("Head")
	var o := _squelette.get_bone_global_rest(tete).origin
	var crane := SphereMesh.new()
	crane.radius = 0.1
	crane.height = 0.22
	crane.radial_segments = 10
	crane.rings = 6
	_attacher(tete, crane, Transform3D(Basis().scaled(Vector3(0.92, 1.05, 1.0)), o + Vector3(0, 0.12, 0.01)))
	var machoire := BoxMesh.new()
	machoire.size = Vector3(0.1, 0.035, 0.08)
	_attacher(tete, machoire, Transform3D(Basis(), o + Vector3(0, 0.035, 0.05)))
	var mat_yeux := StandardMaterial3D.new()
	mat_yeux.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_yeux.albedo_color = COULEUR_YEUX
	for x in [-0.035, 0.035]:
		var oeil := SphereMesh.new()
		oeil.radius = 0.016
		oeil.height = 0.032
		var instance := _attacher(tete, oeil, Transform3D(Basis(), o + Vector3(x, 0.13, 0.085)))
		instance.material_override = mat_yeux


## L'épée rouillée, tenue comme le héros tient la sienne (même squelette, même position).
func _poser_l_epee() -> void:
	var attache := BoneAttachment3D.new()
	attache.bone_name = "hand_r"
	_squelette.add_child(attache)
	var epee := Modeles.creer("Sword_Bronze", Modeles.OBJETS, Color(0.45, 0.4, 0.38))
	epee.transform = load("res://scripts/joueur.gd").EPEE_DANS_LA_MAIN * Transform3D(Basis(), Vector3(0.0, 0.1, 0.0))
	attache.add_child(epee)


## Accroche une forme à un os : « voulue » est sa place sur le squelette au repos.
func _attacher(os: int, forme: Mesh, voulue: Transform3D) -> MeshInstance3D:
	var attache := BoneAttachment3D.new()
	attache.bone_name = _squelette.get_bone_name(os)
	_squelette.add_child(attache)
	var instance := MeshInstance3D.new()
	instance.mesh = forme
	instance.material_override = _mat_os
	instance.transform = _squelette.get_bone_global_rest(os).affine_inverse() * voulue
	attache.add_child(instance)
	return instance


func _preparer_animations(corps: Node3D) -> void:
	_anim = AnimationPlayer.new()
	corps.add_child(_anim)
	_anim.root_node = NodePath("..")
	for bibli in [["", ANIMATIONS], ["ual2", ANIMATIONS_2]]:
		var source := (load(bibli[1]) as PackedScene).instantiate()
		var lecteur := source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		_anim.add_animation_library(bibli[0], lecteur.get_animation_library(""))
		source.free()
	for boucle in ["Jog_Fwd", "Sword_Idle"]:
		_anim.get_animation(boucle).loop_mode = Animation.LOOP_LINEAR
