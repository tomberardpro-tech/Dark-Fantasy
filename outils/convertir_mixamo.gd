extends SceneTree
## Outil (à lancer une fois, sans fenêtre) : convertit les animations Mixamo du dossier
## assets/mixamo/ pour le squelette du héros (Quaternius, 65 os), et les range dans
## assets/mixamo/epee_heros.res (une bibliothèque d'animations).
##
## Commande : Godot --headless --path . --script outils/convertir_mixamo.gd
##
## Principe : pour chaque image, on lit l'orientation de chaque os Mixamo dans le monde,
## on calcule comment il a tourné depuis sa pose de repos, et on applique la même rotation
## à l'os correspondant du héros. Les deux squelettes sont au repos en pose en T ; les
## petites différences de pose de repos (cuisses) sont corrigées os par os.

const DOSSIER := "res://assets/mixamo/"
const SORTIE := "res://assets/mixamo/epee_heros.res"
const HEROS := "res://assets/personnage/Male_Peasant.gltf"
const IMAGES_PAR_SECONDE := 30.0

## Os Mixamo → os du héros.
const CORRESPONDANCE := {
	"Hips": "pelvis", "Spine": "spine_01", "Spine1": "spine_02", "Spine2": "spine_03",
	"Neck": "neck_01", "Head": "Head",
	"LeftShoulder": "clavicle_l", "LeftArm": "upperarm_l", "LeftForeArm": "lowerarm_l", "LeftHand": "hand_l",
	"RightShoulder": "clavicle_r", "RightArm": "upperarm_r", "RightForeArm": "lowerarm_r", "RightHand": "hand_r",
	"LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l", "LeftToeBase": "ball_l",
	"RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r", "RightToeBase": "ball_r",
	"LeftHandThumb1": "thumb_01_l", "LeftHandThumb2": "thumb_02_l", "LeftHandThumb3": "thumb_03_l",
	"LeftHandIndex1": "index_01_l", "LeftHandIndex2": "index_02_l", "LeftHandIndex3": "index_03_l",
	"LeftHandMiddle1": "middle_01_l", "LeftHandMiddle2": "middle_02_l", "LeftHandMiddle3": "middle_03_l",
	"LeftHandRing1": "ring_01_l", "LeftHandRing2": "ring_02_l", "LeftHandRing3": "ring_03_l",
	"LeftHandPinky1": "pinky_01_l", "LeftHandPinky2": "pinky_02_l", "LeftHandPinky3": "pinky_03_l",
	"RightHandThumb1": "thumb_01_r", "RightHandThumb2": "thumb_02_r", "RightHandThumb3": "thumb_03_r",
	"RightHandIndex1": "index_01_r", "RightHandIndex2": "index_02_r", "RightHandIndex3": "index_03_r",
	"RightHandMiddle1": "middle_01_r", "RightHandMiddle2": "middle_02_r", "RightHandMiddle3": "middle_03_r",
	"RightHandRing1": "ring_01_r", "RightHandRing2": "ring_02_r", "RightHandRing3": "ring_03_r",
	"RightHandPinky1": "pinky_01_r", "RightHandPinky2": "pinky_02_r", "RightHandPinky3": "pinky_03_r",
}
## Pour corriger la pose de repos, on compare la direction de chaque os vers cet os enfant.
const ENFANT := {
	"Hips": "Spine", "Spine": "Spine1", "Spine1": "Spine2", "Spine2": "Neck", "Neck": "Head",
	"LeftShoulder": "LeftArm", "LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand", "LeftHand": "LeftHandMiddle1",
	"RightShoulder": "RightArm", "RightArm": "RightForeArm", "RightForeArm": "RightHand", "RightHand": "RightHandMiddle1",
	"LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "LeftFoot": "LeftToeBase",
	"RightUpLeg": "RightLeg", "RightLeg": "RightFoot", "RightFoot": "RightToeBase",
}


func _initialize() -> void:
	# On attend que le jeu ait démarré : sinon les animations ne s'appliquent pas encore.
	_lancer.call_deferred()


func _lancer() -> void:
	var heros := (load(HEROS) as PackedScene).instantiate()
	var cible: Skeleton3D = heros.find_children("*", "Skeleton3D", true, false)[0]
	var chemin_cible := "Armature/Skeleton3D:"
	var bibliotheque := AnimationLibrary.new()
	for fichier in DirAccess.get_files_at(DOSSIER):
		if not fichier.ends_with(".fbx"):
			continue
		var source := (load(DOSSIER + fichier) as PackedScene).instantiate()
		# Dans la scène, pour que l'animation s'applique vraiment au squelette.
		root.add_child(source)
		var lecteurs := source.find_children("*", "AnimationPlayer", true, false)
		if lecteurs.is_empty():
			source.free()
			continue
		var lecteur: AnimationPlayer = lecteurs[0]
		var nom_anim: String = lecteur.get_animation_list()[0]
		var longueur := lecteur.get_animation(nom_anim).length
		if longueur < 0.1:
			source.free()
			continue
		var src: Skeleton3D = source.find_children("*", "Skeleton3D", true, false)[0]
		var animation := _convertir(lecteur, nom_anim, longueur, src, cible, chemin_cible)
		var nom := fichier.get_basename().replace("sword and shield ", "").replace(" ", "_").replace("(", "").replace(")", "")
		bibliotheque.add_animation(nom, animation)
		print("converti : ", nom, " (", snappedf(longueur, 0.01), " s)")
		source.free()
	ResourceSaver.save(bibliotheque, SORTIE)
	print("ENREGISTRE ", SORTIE, " : ", bibliotheque.get_animation_list().size(), " animations")
	heros.free()
	quit()


func _convertir(lecteur: AnimationPlayer, nom_anim: String, longueur: float, src: Skeleton3D, cible: Skeleton3D, chemin: String) -> Animation:
	# Pose de repos Mixamo, corrigée pour pointer comme celle du héros.
	var repos_src := {}
	for m in CORRESPONDANCE:
		var i := src.find_bone("mixamorig_" + m)
		var rest := src.get_bone_global_rest(i).basis.orthonormalized()
		if ENFANT.has(m):
			var dir_src := (src.get_bone_global_rest(src.find_bone("mixamorig_" + ENFANT[m])).origin - src.get_bone_global_rest(i).origin).normalized()
			var t := cible.find_bone(CORRESPONDANCE[m])
			var t_enfant := cible.find_bone(CORRESPONDANCE[ENFANT[m]])
			var dir_cible := (cible.get_bone_global_rest(t_enfant).origin - cible.get_bone_global_rest(t).origin).normalized()
			rest = Basis(Quaternion(dir_src, dir_cible)) * rest
		repos_src[m] = rest
	var hanches_src := src.get_bone_global_rest(src.find_bone("mixamorig_Hips")).origin
	var hanches_cible := cible.get_bone_global_rest(cible.find_bone("pelvis")).origin
	var echelle: float = hanches_cible.y / maxf(hanches_src.y, 0.001)

	var animation := Animation.new()
	animation.length = longueur
	var pistes := {}
	for i in cible.get_bone_count():
		var piste := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(piste, chemin + cible.get_bone_name(i))
		pistes[i] = piste
	var piste_bassin := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(piste_bassin, chemin + "pelvis")

	lecteur.play(nom_anim)
	var images := int(ceil(longueur * IMAGES_PAR_SECONDE))
	for k in images + 1:
		var temps: float = min(k / IMAGES_PAR_SECONDE, longueur)
		lecteur.seek(temps, true)
		# Orientation voulue de chaque os du héros, dans le repère du personnage.
		var globales := {}
		for i in cible.get_bone_count():
			var parent := cible.get_bone_parent(i)
			var nom := cible.get_bone_name(i)
			var m := _mixamo_de(nom)
			var g: Basis
			if m != "":
				var g_src := src.get_bone_global_pose(src.find_bone("mixamorig_" + m)).basis.orthonormalized()
				g = g_src * repos_src[m].inverse() * cible.get_bone_global_rest(i).basis.orthonormalized()
			else:
				var base_parent: Basis = globales[parent] if parent >= 0 else Basis()
				g = base_parent * cible.get_bone_rest(i).basis.orthonormalized()
			globales[i] = g
			var locale: Basis = g if parent < 0 else (globales[parent] as Basis).inverse() * g
			animation.rotation_track_insert_key(pistes[i], temps, locale.get_rotation_quaternion())
		# Le bassin monte et descend comme dans l'animation (à la taille du héros), sans
		# avancer : le jeu gère lui-même les déplacements.
		var hanches := src.get_bone_global_pose(src.find_bone("mixamorig_Hips")).origin
		var decalage: Vector3 = (hanches - hanches_src) * echelle
		var pos_globale := hanches_cible + Vector3(0.0, decalage.y, 0.0)
		var parent_bassin := cible.get_bone_parent(cible.find_bone("pelvis"))
		var pos_locale := pos_globale
		if parent_bassin >= 0:
			pos_locale = cible.get_bone_global_rest(parent_bassin).affine_inverse() * pos_globale
		animation.position_track_insert_key(piste_bassin, temps, pos_locale)
	return animation


func _mixamo_de(nom_cible: String) -> String:
	for m in CORRESPONDANCE:
		if CORRESPONDANCE[m] == nom_cible:
			return m
	return ""
