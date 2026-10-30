extends CharacterBody3D
## Le héros : tenue « Paysan » de Quaternius, tête et cheveux longs du pack Universal
## Base Characters, animé avec les Universal Animation Library 1 et 2.
## Commandes :
## - ZQSD pour marcher, Maj pour courir, Espace pour une roulade ;
## - clic gauche : un coup d'épée droit devant, dans la direction où l'on court
##   (l'épée sort toute seule) ; recliquer donne un deuxième coup, différent ;
## - clic droit : un petit bond et un coup au sol qui repousse les ennemis autour ;
## - R pour sortir ou ranger l'épée, E pour interagir.
## On peut continuer à courir en frappant : seul le haut du corps donne le coup.
## Il a une barre de vie ; à zéro, il se réveille au dernier feu de camp.

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
## De combien on allonge les cheveux (1 = deux fois plus longs).
@export var longueur_cheveux := 1.3
@export var vie_max := 100.0
## Distance à laquelle on peut toucher un ennemi avec l'épée.
@export var portee_epee := 2.2
## Le bond du clic droit : sa hauteur (vitesse de départ), la portée du coup au sol
## et ses dégâts.
@export var force_bond := 3.4
@export var rayon_coup_au_sol := 2.6
@export var degats_coup_au_sol := 10.0

const ANIMATIONS := "res://assets/personnage/UAL1_Standard.glb"
const ANIMATIONS_2 := "res://assets/personnage/UAL2_Standard.glb"
const CORPS := "res://assets/personnage/Superhero_Male_FullBody.gltf"
const CHEVEUX := "res://assets/personnage/Hair_Long.gltf"
const EN_BOUCLE := ["Idle", "Jog_Fwd", "Sprint", "Sitting_Idle", "Sword_Idle"]
## Les os gardés pour la tête (le reste du corps de base est caché par la tenue).
const OS_DE_LA_TETE := ["Head", "neck_01"]
## Les os du haut du corps : quand le héros court en frappant, eux seuls donnent le coup.
const OS_DU_HAUT := ["spine_01", "spine_02", "spine_03", "neck_01", "Head",
	"clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r"]

## Les états du bas du corps (déplacements) et leur animation.
const ETATS := {
	"repos": "Idle", "course": "Jog_Fwd", "sprint": "Sprint", "garde": "Sword_Idle",
	"roulade": "Roll", "assis": "Sitting_Idle", "s_asseoir": "Sitting_Enter", "mort": "Death01",
	"saut": "Jump",
}

## Dégainer : on joue le début du lancer par-dessus l'épaule ; la main est derrière
## l'épaule à ce moment (mesuré), c'est là que l'épée passe du dos à la main.
const ANIM_DEGAINER := "ual2/OverhandThrow"
const MAIN_DANS_LE_DOS := 0.25
## Position de l'épée dans la main, mesurée sur l'animation « Sword_Idle » :
## la lame sort du côté du pouce, dans l'axe des jointures, et la poignée est serrée au
## creux du poing (3,5 cm côté paume : avant, elle passait au ras des jointures).
const EPEE_DANS_LA_MAIN := Transform3D(
	Vector3(-0.996105, -0.086398, 0.017613), Vector3(-0.005154, 0.256456, 0.966542),
	Vector3(-0.088024, 0.962687, -0.255902), Vector3(-0.035, 0.112, -0.005))
## Le combo : pour chaque coup, son animation, sa durée, le moment où il touche,
## ses dégâts, puis son retour en garde (et la durée de ce retour).
const COUPS := [
	{"anim": "ual2/Sword_Regular_A", "duree": 0.43, "touche": 0.22, "degats": 10.0, "retour": "ual2/Sword_Regular_A_Rec", "duree_retour": 0.97},
	{"anim": "ual2/Sword_Regular_B", "duree": 0.53, "touche": 0.28, "degats": 12.0, "retour": "ual2/Sword_Regular_B_Rec", "duree_retour": 1.03},
]
## Le bond du clic droit : un passage du « combo lourd » où l'épée est levée puis abattue.
const ANIM_COUP_AU_SOL := "ual2/Sword_Heavy_Combo"
const DEBUT_COUP_AU_SOL := 2.1
const DUREE_COUP_AU_SOL := 1.3

## Les gestes d'épée de Mixamo (pack « Sword and Shield »), convertis pour le héros par
## outils/convertir_mixamo.gd. Ce fichier n'est pas sur GitHub (droits Mixamo) : sans lui,
## le héros garde les coups ci-dessus.
const MIXAMO := "res://assets/mixamo/epee_heros.res"
## Chaque coup ne joue qu'un passage de l'animation (« debut », « longueur », en temps de
## l'animation), un peu accéléré (« vitesse »). Les autres temps sont en vraies secondes :
## mesurés sur la main (l'impact = quand elle va le plus vite). Le retour en garde est la
## fin de la même animation.
const COUPS_MIXAMO := [
	# Coup en diagonale, de l'épaule droite vers l'avant (impact à 0,60 s de l'animation).
	{"anim": "mixamo/slash", "debut": 0.2, "longueur": 1.3, "vitesse": 1.3, "touche": 0.31, "duree": 0.54, "degats": 10.0, "retour": "", "duree_retour": 0.46},
	# Revers, de la gauche vers l'avant (impact à 0,83 s).
	{"anim": "mixamo/slash_3", "debut": 0.3, "longueur": 1.37, "vitesse": 1.3, "touche": 0.41, "duree": 0.62, "degats": 12.0, "retour": "", "duree_retour": 0.44},
]
## Le bond : le héros saute, l'épée au-dessus de la tête, et l'abat au sol (impact à
## 1,17 s de l'animation, soit 0,70 s après le clic). Le saut est dans l'animation.
const BOND_MIXAMO := {"anim": "mixamo/attack", "debut": 0.3, "longueur": 1.9, "vitesse": 1.25, "touche": 0.7}
## Pendant un coup ou un bond, le héros avance un peu (mètres par seconde).
const ELAN_COUP := 1.6
const ELAN_BOND := 3.0
## Sans épée : un coup de poing.
## Trois coups de poing qui s'enchaînent en recliquant : direct du gauche, direct du
## droit, puis un crochet qui repousse. « touche » = quand la main va le plus vite (mesuré).
const POINGS := [
	{"anim": "Punch_Jab", "duree": 0.34, "touche": 0.2, "degats": 4.0, "retour": "", "duree_retour": 0.35, "portee": 1.6, "recul": 3.0},
	{"anim": "Punch_Cross", "duree": 0.4, "touche": 0.24, "degats": 5.0, "retour": "", "duree_retour": 0.4, "portee": 1.6, "recul": 3.5},
	{"anim": "ual2/Melee_Hook", "duree": 0.47, "touche": 0.28, "degats": 8.0, "retour": "ual2/Melee_Hook_Rec", "duree_retour": 0.6, "portee": 1.7, "recul": 7.0},
]
## Quand un coup touche, le temps ralentit un très court instant : le coup a du poids.
const ARRET_SUR_IMAGE := 0.06

var est_assis := false
## L'objet sur lequel il est assis (un tronc près d'un feu), ou rien.
var siege: Node = null
## A-t-il trouvé la vieille épée ?
var a_epee := false
## L'épée est-elle dans sa main ?
var epee_sortie := false
var vie := 100.0
var est_mort := false
## Vrai quand le héros est dans une pièce (la maison du chef…).
var a_l_interieur := false
## L'or et ce qu'on a acheté aux marchands (voir boutiques.gd).
var pieces := 0
## Les potions qu'on porte : nom de la potion → combien.
var potions := {}
## L'arme et l'armure achetées (vides : la vieille épée et la tenue de paysan).
var arme: Dictionary = {}
var armure: Dictionary = {}
## Les effets des potions de force et de résistance, et le temps qu'il leur reste.
var _force := 0.0
var _force_restante := 0.0
var _resistance := 0.0
var _resistance_restante := 0.0

var _clic_avant := false
var _clic_droit_avant := false
## Le petit bond du clic droit : en l'air ou non, et depuis combien de temps.
var _en_bond := false
var _temps_bond := 0.0
var _roulade_restante := 0.0
var _direction_roulade := Vector3.ZERO
var _attente_roulade := 0.0
var _recul := Vector3.ZERO
var _anim: AnimationPlayer
var _arbre: AnimationTree
var _geste: AnimationNodeAnimation
var _geste_unique: AnimationNodeOneShot
var _squelette: Skeleton3D
var _epee_dos: Node3D
var _epee_main: Node3D
var _trainee: MeshInstance3D
## Ce que fait le haut du corps : "" (rien), "degainer", "ranger", "attaque", "touche".
var _action := ""
var _temps_action := 0.0
## Le combo : coup en cours, sa phase (« coup » ou « retour »), s'il a déjà touché,
## et s'il y a eu un clic pour enchaîner.
var _coup := 0
var _phase := ""
var _a_touche := false
var _clic_en_attente := false
var _coup_actuel: Dictionary = {}
## Les coups et le bond utilisés : ceux de Mixamo s'ils sont là, sinon les anciens.
var _coups: Array = COUPS
var _bond: Dictionary = {}
var _geste_vitesse: AnimationNodeTimeScale
## Les cheveux longs (leur matériau reçoit chaque image la position de la tête).
var _cheveux: ShaderMaterial
var _os_tete := -1
var _tete_avant := Vector3.ZERO
var _elan_cheveux := Vector3.ZERO
var _temps := 0.0
## Le temps qui reste avant le prochain bruit de pas.
var _prochain_pas := 0.0
## Les oreilles du joueur, sur le héros, tournées comme la caméra (gauche = gauche de l'écran).
var _oreilles: AudioListener3D

@onready var _visuel: Node3D = $Visuel
@onready var _modele: Node3D = $Visuel/Modele


func _ready() -> void:
	_squelette = _modele.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_os_tete = _squelette.find_bone("Head")
	_preparer_animations()
	_ajouter_tete_et_cheveux()
	_teinter_tenue()
	if Sauvegarde.donnee("epee", false):
		prendre_epee()
	vie = vie_max
	_changer_vie.call_deferred(0.0)
	_montrer_inventaire.call_deferred()
	# On entend le monde depuis le héros (pas depuis la caméra, qui est loin au-dessus).
	_oreilles = AudioListener3D.new()
	add_child(_oreilles)
	_oreilles.position.y = 1.4
	_oreilles.make_current.call_deferred()
	get_viewport().audio_listener_enable_3d = true


## Cherche ce qui est à portée (tronc, coffre…), affiche « E : … » et réagit à E.
## Fait aussi bouger les cheveux.
func _process(delta: float) -> void:
	_temps += delta
	_animer_cheveux(delta)
	var camera := get_viewport().get_camera_3d()
	if _oreilles and camera:
		_oreilles.global_basis = camera.global_basis
	# La traînée de la lame pendant les coups.
	if _trainee and _epee_main:
		var lame := _epee_main.global_transform
		var frappe := epee_sortie and ((_action == "attaque" and _phase == "coup") or _en_bond)
		_trainee.suivre(lame * Vector3(0, 0.15, 0), lame * Vector3(0, 0.9, 0), frappe, delta)
	var interface := get_tree().get_first_node_in_group("interface")
	_raccourcis(interface)
	if est_mort:
		return
	# Pendant une conversation, c'est la bulle qui réagit à E.
	if interface and (interface.dialogue_ouvert() or interface.boutique_ouverte()):
		interface.cacher()
		return
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


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var interface := get_tree().get_first_node_in_group("interface")
	var en_dialogue: bool = interface != null and interface.dialogue_ouvert()
	if est_mort or en_dialogue:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if en_dialogue:
			_choisir_deplacement(0.0)
		return

	# Clic gauche : un coup d'épée (recliquer enchaîne le combo).
	var clic := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if clic and not _clic_avant and not est_assis:
		_clic_gauche()
	_clic_avant = clic
	# Clic droit : un petit bond et un coup au sol qui repousse les ennemis autour.
	var clic_droit := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if clic_droit and not _clic_droit_avant and not est_assis:
		_bondir()
	_clic_droit_avant = clic_droit

	_effets_des_potions(delta)

	if Input.is_action_just_pressed("degainer") and a_epee and not est_assis and _action == "":
		if epee_sortie:
			_ranger_epee()
		else:
			_degainer()

	_avancer_action(delta)

	var direction := _direction_clavier()

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
		# On peut courir en frappant : le coup ne concerne que le haut du corps.
		var vitesse := vitesse_course if Input.is_action_pressed("courir") else vitesse_marche
		velocity.x = direction.x * vitesse + _recul.x
		velocity.z = direction.z * vitesse + _recul.z
		# Sur place, le coup (avant qu'il touche) et le bond emportent le héros vers l'avant.
		if direction.length() < 0.01:
			var elan := 0.0
			if _en_bond:
				elan = ELAN_BOND
			elif _action == "attaque" and _phase == "coup" and not _a_touche:
				elan = ELAN_COUP
			var devant := -_visuel.global_basis.z
			velocity.x += devant.x * elan
			velocity.z += devant.z * elan
	_recul = _recul.lerp(Vector3.ZERO, 1.0 - exp(-10.0 * delta))

	var au_sol := Vector3(velocity.x, 0.0, velocity.z)
	# Pendant un coup sur place, le héros garde la direction de son coup.
	if au_sol.length() > 0.1 and not (_action == "attaque" and direction.length() < 0.01):
		_regarder(au_sol, delta)
	move_and_slide()
	# Le bond retombe : coup au sol (avec Mixamo, au moment où l'épée frappe le sol).
	if _en_bond:
		_temps_bond += delta
		if _bond.is_empty():
			if is_on_floor() and _temps_bond > 0.15:
				_impact_au_sol()
		elif _temps_bond >= _bond["touche"]:
			_impact_au_sol()
	_choisir_deplacement(au_sol.length())
	_bruit_de_pas(au_sol.length(), delta)


# --- Déplacements ---------------------------------------------------------

func _choisir_deplacement(vitesse: float) -> void:
	if _en_bond:
		# Pendant le bond, le geste du coup au sol fait bouger tout le corps.
		_etat("garde" if epee_sortie else "repos")
	elif _roulade_restante > 0.0:
		_arbre.set("parameters/roulade_vitesse/scale", _anim.get_animation("Roll").length / duree_roulade)
		_etat("roulade")
	elif vitesse > 5.5:
		_etat("sprint")
	elif vitesse > 0.5:
		_etat("course")
	else:
		_etat("garde" if epee_sortie else "repos")


## Un bruit de pas à chaque foulée, selon le sol : terre, planches du pont, eau du ruisseau.
func _bruit_de_pas(vitesse: float, delta: float) -> void:
	if vitesse < 0.5 or not is_on_floor() or _en_bond or _roulade_restante > 0.0 or est_assis:
		_prochain_pas = 0.12
		return
	_prochain_pas -= delta
	if _prochain_pas > 0.0:
		return
	_prochain_pas = 0.27 if vitesse > 5.5 else 0.34
	var sol := "pas_terre"
	if global_position.y > 0.05:
		sol = "pas_bois"
	elif Chemin.distance_au_ruisseau(global_position) < 1.6:
		sol = "pas_eau"
	Sons.jouer(sol, global_position, 2.0 if vitesse > 5.5 else 0.0)


func _etat(nom: String) -> void:
	if _arbre.get("parameters/deplacement/current_state") != nom:
		_arbre.set("parameters/deplacement/transition_request", nom)


func _regarder(direction: Vector3, delta: float, tout_de_suite := false) -> void:
	var angle := atan2(-direction.x, -direction.z)
	if tout_de_suite:
		_visuel.rotation.y = angle
	else:
		_visuel.rotation.y = lerp_angle(_visuel.rotation.y, angle, 1.0 - exp(-12.0 * delta))


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
	Sons.jouer("tissu", self)


## Assoit le personnage à un endroit précis, tourné dans une direction.
## « tout_de_suite » : déjà assis (au lancement du jeu), sans l'animation pour s'asseoir.
func asseoir(point: Vector3, regard: Vector3, tout_de_suite := false, sur: Node = null) -> void:
	est_assis = true
	siege = sur
	velocity = Vector3.ZERO
	global_position = point
	reset_physics_interpolation()
	_visuel.rotation.y = atan2(-regard.x, -regard.z)
	# On range l'épée sans animation avant de s'asseoir.
	_mettre_epee_dans_le_dos()
	_arreter_geste()
	# Un peu en arrière et plus haut : il est posé sur le tronc.
	_modele.position = Vector3(0.0, assise_hauteur, assise_recul)
	if tout_de_suite:
		_etat("assis")
	else:
		_etat("s_asseoir")
		await get_tree().create_timer(_anim.get_animation("Sitting_Enter").length - 0.1).timeout
		if est_assis:
			_etat("assis")


func se_relever() -> void:
	est_assis = false
	siege = null
	_modele.position = Vector3.ZERO
	_etat("repos")


# --- Combat ---------------------------------------------------------------

## Clic gauche : sur un ennemi, on l'attaque ; sur le sol, on y va.
## Clic gauche : on frappe droit devant, dans la direction où l'on court
## (ou là où l'on regarde si on est immobile). Pendant un coup, le clic enchaîne le suivant.
func _clic_gauche() -> void:
	if _action == "attaque":
		_clic_en_attente = true
		return
	if _action != "" or _en_bond:
		return
	var direction := _direction_clavier()
	if direction.length() > 0.01:
		_regarder(direction, 0.0, true)
	_commencer_attaque()


## Clic droit : un petit bond rapide ; en retombant, coup au sol qui blesse et repousse
## les ennemis autour.
func _bondir() -> void:
	if _en_bond or not is_on_floor() or (_action != "" and _action != "attaque"):
		return
	_arreter_geste()
	if a_epee and not epee_sortie:
		_epee_dos.visible = false
		_epee_main.visible = true
		epee_sortie = true
	_en_bond = true
	_temps_bond = 0.0
	_action = "bond"
	if not _bond.is_empty():
		# Le saut est dans l'animation Mixamo : le corps ne quitte pas le sol pour le jeu.
		Sons.jouer("souffle_lourd", self)
		Sons.jouer_apres(0.15, "tissu", self)
		Sons.jouer_apres(0.5, "souffle_epee", self, 2.0, 0.85)
		_jouer_geste(_bond["anim"], _bond["longueur"], false, false, _bond["debut"], _bond["vitesse"])
		return
	velocity.y = force_bond
	# Tout le corps joue le moment du « combo lourd » où le héros lève l'épée au-dessus de
	# sa tête puis l'abat jusqu'au sol (mesuré : la main touche presque le sol 0,65 s après
	# le début de ce passage, à peu près quand le bond retombe).
	_jouer_geste(ANIM_COUP_AU_SOL, DUREE_COUP_AU_SOL, false, false, DEBUT_COUP_AU_SOL)


func _impact_au_sol() -> void:
	Sons.jouer("impact_sol", global_position)
	Sons.jouer("impact_sol_bois", global_position)
	_en_bond = false
	# Le héros finit son geste, puis il est libre.
	get_tree().create_timer(0.45).timeout.connect(func(): if _action == "bond": _action = "")
	for ennemi in get_tree().get_nodes_in_group("ennemi"):
		if ennemi.est_vivant() and ennemi.global_position.distance_to(global_position) < rayon_coup_au_sol:
			ennemi.prendre_coup(degats_coup_au_sol * multiplicateur_degats(), global_position, 9.0)
	_onde_de_choc()


## Un anneau de poussière qui s'élargit au sol, à l'endroit de l'impact.
func _onde_de_choc() -> void:
	var anneau := TorusMesh.new()
	anneau.inner_radius = 0.85
	anneau.outer_radius = 1.0
	anneau.rings = 24
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.55, 0.45, 0.35, 0.7)
	anneau.material = mat
	var onde := MeshInstance3D.new()
	onde.mesh = anneau
	onde.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	onde.top_level = true
	add_child(onde)
	onde.global_position = global_position + Vector3(0, 0.08, 0)
	onde.scale = Vector3(0.3, 0.15, 0.3)
	var anim := create_tween().set_parallel()
	anim.tween_property(onde, "scale", Vector3(rayon_coup_au_sol, 0.15, rayon_coup_au_sol), 0.35).set_ease(Tween.EASE_OUT)
	anim.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	anim.chain().tween_callback(onde.queue_free)


## Premier coup : l'épée sort toute seule si elle est dans le dos.
func _commencer_attaque() -> void:
	if a_epee and not epee_sortie:
		_epee_dos.visible = false
		_epee_main.visible = true
		epee_sortie = true
	_lancer_coup(0)


## Les coups qui s'enchaînent : à l'épée si elle est sortie, sinon aux poings.
func _serie() -> Array:
	return _coups if epee_sortie else POINGS


func _lancer_coup(numero: int) -> void:
	_coup = numero
	_lancer(_serie()[numero])


func _lancer(coup: Dictionary) -> void:
	_coup_actuel = coup
	_action = "attaque"
	_phase = "coup"
	_temps_action = 0.0
	_a_touche = false
	_clic_en_attente = false
	_jouer_geste(coup["anim"], coup.get("longueur", 0.0), false, true, coup.get("debut", 0.0), coup.get("vitesse", 1.0))
	# Le souffle du coup, calé un peu avant le moment où il touche.
	var souffle := "souffle_epee" if epee_sortie else "souffle_poing"
	Sons.jouer_apres(maxf(coup["touche"] - 0.14, 0.0), souffle, self)


## Le temps passe pour le geste en cours : le coup touche, puis on enchaîne ou on revient
## en garde.
func _avancer_action(delta: float) -> void:
	if _action != "attaque":
		return
	_temps_action += delta
	if _phase == "coup":
		if not _a_touche and _temps_action >= _coup_actuel["touche"]:
			_a_touche = true
			_toucher_les_ennemis(_coup_actuel["degats"], _coup_actuel.get("portee", portee_epee), _coup_actuel.get("recul", 5.0))
		if _temps_action >= _coup_actuel["duree"]:
			var suivant := _coup + 1
			if _clic_en_attente and suivant < _serie().size():
				_lancer_coup(suivant)
			elif _coup_actuel["duree_retour"] > 0.0:
				_phase = "retour"
				_temps_action = 0.0
				# Sans animation de retour à part, la fin du geste en cours sert de retour.
				if _coup_actuel["retour"] != "":
					_jouer_geste(_coup_actuel["retour"])
			else:
				_fin_attaque()
	elif _phase == "retour":
		# Un clic pendant le retour en garde enchaîne tout de suite le coup suivant.
		if _clic_en_attente and _coup + 1 < _serie().size():
			_lancer_coup(_coup + 1)
		elif _temps_action >= _coup_actuel["duree_retour"]:
			_fin_attaque()


func _fin_attaque() -> void:
	_action = ""
	_phase = ""
	_coup = 0
	_clic_en_attente = false


## Les ennemis devant le héros, à portée, prennent le coup.
func _toucher_les_ennemis(degats: float, portee: float, recul: float) -> void:
	var devant := -_visuel.global_basis.z
	var touche := false
	for ennemi in get_tree().get_nodes_in_group("ennemi"):
		if not ennemi.est_vivant():
			continue
		var vers: Vector3 = ennemi.global_position - global_position
		vers.y = 0.0
		if vers.length() < portee and (vers.length() < 0.8 or devant.dot(vers.normalized()) > 0.3):
			ennemi.prendre_coup(degats * multiplicateur_degats(), global_position, recul)
			_bruit_d_impact(ennemi.global_position + Vector3.UP, recul)
			touche = true
	if touche:
		_arret_sur_image()


## Le bruit d'un coup qui touche : la lame qui cogne les os (avec un léger tintement du
## métal), ou un coup de poing (plus lourd pour le crochet).
func _bruit_d_impact(ou: Vector3, recul: float) -> void:
	if epee_sortie:
		Sons.jouer("coup_epee", ou)
		Sons.jouer("tinte_lame", ou)
	else:
		Sons.jouer("coup_poing_lourd" if recul > 5.0 else "coup_poing", ou)
	Sons.jouer("os_choc", ou, -4.0)


## Le jeu tourne au ralenti un instant (le minuteur, lui, compte en temps réel).
func _arret_sur_image() -> void:
	Engine.time_scale = 0.15
	await get_tree().create_timer(ARRET_SUR_IMAGE, true, false, true).timeout
	Engine.time_scale = 1.0


## Un ennemi nous frappe.
func prendre_coup(degats: float, depuis: Vector3) -> void:
	if est_mort or _roulade_restante > 0.0:
		return
	if est_assis:
		se_relever()
	_changer_vie(-degats * (1.0 - armure.get("protection", 0.0)) * (1.0 - _resistance))
	Sons.jouer("heros_touche", global_position + Vector3.UP)
	Sons.jouer("tissu", self)
	var recul := global_position - depuis
	recul.y = 0.0
	_recul = recul.normalized() * 4.0
	if vie <= 0.0:
		_mourir()
	elif _action != "attaque":
		_action = "touche"
		_jouer_geste("Hit_Chest")
		await get_tree().create_timer(0.45).timeout
		if _action == "touche":
			_action = ""


func _changer_vie(difference: float) -> void:
	vie = clampf(vie + difference, 0.0, vie_max)
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.vie(vie, vie_max)


func est_vivant() -> bool:
	return not est_mort


## Plus de vie : il s'écroule, puis se réveille au dernier feu de camp.
func _mourir() -> void:
	est_mort = true
	_arreter_geste()
	_etat("mort")
	Sons.jouer_apres(0.6, "chute", self)
	await get_tree().create_timer(3.0).timeout
	var interface := get_tree().get_first_node_in_group("interface")
	for feu in get_tree().get_nodes_in_group("interactif"):
		if feu.has_method("reveiller_au_feu") and feu.est_le_dernier_feu():
			feu.reveiller_au_feu(self)
	est_mort = false
	_changer_vie(vie_max)
	get_tree().call_group("ennemi", "reinitialiser")
	if interface:
		interface.notifier("Vous vous réveillez près du feu")


# --- Les portes -----------------------------------------------------------------

## Le héros passe une porte : il apparaît à « arrivee », tourné vers « regard », et la
## caméra le rejoint tout de suite.
func teleporter(arrivee: Vector3, regard: Vector3, dedans: bool) -> void:
	if est_assis:
		se_relever()
	global_position = arrivee
	velocity = Vector3.ZERO
	_recul = Vector3.ZERO
	_regarder(regard, 0.0, true)
	reset_physics_interpolation()
	a_l_interieur = dedans
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("sauter"):
		camera.sauter()


## Raccourcis de travail (pour Tom, pendant la fabrication du jeu) : H ramène au feu de
## départ, J à l'entrée de Bruneval, K sur la place, L chez le chef, M sur le chemin juste
## avant les squelettes. Hors du feu de départ, le héros reçoit l'épée s'il ne l'a pas
## encore, pour pouvoir tout essayer.
func _raccourcis(interface: Node) -> void:
	if interface == null or est_mort or interface.dialogue_ouvert() or interface.boutique_ouverte():
		return
	var hameau := get_tree().get_first_node_in_group("bruneval")
	var arrivee := Vector3.INF
	var regard := Chemin.HAUT_ECRAN
	var dedans := false
	if Input.is_action_just_pressed("aller_feu"):
		# Debout devant le tronc du feu de départ, tourné vers le feu.
		for objet in get_tree().get_nodes_in_group("interactif"):
			if objet.has_method("reveiller_au_feu") and objet.feu_de_depart:
				regard = objet.regard()
				arrivee = objet.point_assise() + regard * 0.5
	elif Input.is_action_just_pressed("aller_entree"):
		arrivee = Chemin.bruneval(0.0, -18.0)
	elif Input.is_action_just_pressed("aller_place"):
		arrivee = Chemin.bruneval(0.0, -4.8)
	elif Input.is_action_just_pressed("aller_chef") and hameau:
		arrivee = hameau.arrivee_chez_le_chef()
		dedans = true
	elif Input.is_action_just_pressed("aller_squelettes"):
		# Sur le chemin, 9 m avant le squelette le plus proche du départ.
		var courbe := Chemin.courbe_chemin
		var plus_tot := INF
		for ennemi in get_tree().get_nodes_in_group("ennemi"):
			plus_tot = minf(plus_tot, courbe.get_closest_offset(ennemi.global_position))
		if plus_tot < INF:
			arrivee = courbe.sample_baked(maxf(plus_tot - 9.0, 0.0))
			regard = courbe.sample_baked(plus_tot) - arrivee
			regard.y = 0.0
			arrivee.y = 0.0
	if arrivee == Vector3.INF:
		return
	if not a_epee and not Input.is_action_just_pressed("aller_feu"):
		prendre_epee()
	interface.passer_la_porte(self, arrivee, regard, dedans)


# --- L'or, les achats et les potions ------------------------------------------

## Les dégâts de nos coups : ceux de l'arme achetée, plus la potion de force.
func multiplicateur_degats() -> float:
	return arme.get("degats", 1.0) * (1.0 + _force)


func ajouter_pieces(nombre: int) -> void:
	pieces += nombre
	_montrer_inventaire()


## Achète un objet d'un marchand (voir boutiques.gd). Renvoie false s'il n'y a pas assez d'or.
func acheter(objet: Dictionary) -> bool:
	if pieces < objet["prix"]:
		return false
	pieces -= objet["prix"]
	match objet["sorte"]:
		"arme":
			arme = objet
			if not a_epee:
				prendre_epee()
			else:
				Modeles.teinter(_epee_main, objet["teinte"])
				Modeles.teinter(_epee_dos, objet["teinte"])
		"armure":
			armure = objet
			teinte = objet["teinte"]
			_teinter_tenue()
		"potion":
			potions[objet["nom"]] = potions.get(objet["nom"], 0) + 1
	_montrer_inventaire()
	return true


## Ce qu'on possède déjà (pour griser l'arme ou l'armure qu'on porte dans la boutique).
func possede(objet: Dictionary) -> bool:
	return arme == objet or armure == objet


## A (ou 1) : une potion de soin (la petite d'abord) ; 2 : force ; 3 : résistance.
func _effets_des_potions(delta: float) -> void:
	_force_restante -= delta
	if _force_restante <= 0.0:
		_force = 0.0
	_resistance_restante -= delta
	if _resistance_restante <= 0.0:
		_resistance = 0.0
	if Input.is_action_just_pressed("potion_soin") and vie < vie_max:
		for nom in ["Potion de soin", "Grande potion de soin"]:
			if _boire(nom):
				break
	if Input.is_action_just_pressed("potion_force"):
		_boire("Potion de force")
	if Input.is_action_just_pressed("potion_resistance"):
		_boire("Potion de résistance")


func _boire(nom: String) -> bool:
	if potions.get(nom, 0) <= 0:
		return false
	potions[nom] -= 1
	var potion: Dictionary = {}
	for objet in Boutiques.MEDECIN:
		if objet["nom"] == nom:
			potion = objet
	if potion.has("soin"):
		_changer_vie(potion["soin"])
	if potion.has("force"):
		_force = potion["force"]
		_force_restante = potion["duree"]
	if potion.has("resistance"):
		_resistance = potion["resistance"]
		_resistance_restante = potion["duree"]
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.notifier(nom + " bue")
	_montrer_inventaire()
	return true


func _montrer_inventaire() -> void:
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.inventaire(pieces, potions)


# --- L'épée ---------------------------------------------------------------

## Le héros trouve la vieille épée : elle est rangée dans son dos.
func prendre_epee() -> void:
	if a_epee:
		return
	a_epee = true
	# L'épée du Fantasy Props MegaKit, un peu rouillée (teinte sombre), en deux exemplaires :
	# un dans le dos, un dans la main. On n'en montre qu'un à la fois.
	_epee_dos = _accrocher_epee("spine_03")
	# Plaquée contre le dos, en diagonale : la poignée au-dessus de l'épaule droite, la pointe
	# vers la hanche gauche. Le héros regarde vers son +Z, sa droite est vers -X, et le dos de
	# sa chemise est à 13,5 cm derrière la colonne (mesuré) : la lame est posée juste contre.
	var dans_le_dos := Transform3D(Basis(Vector3.BACK, PI + 0.5), Vector3(-0.08, 1.48, -0.175))
	_epee_dos.transform = _squelette.get_bone_global_rest(_squelette.find_bone("spine_03")).affine_inverse() * dans_le_dos
	_epee_main = _accrocher_epee("hand_r")
	# La poignée (un peu sous l'origine du modèle) au creux de la main.
	_epee_main.transform = EPEE_DANS_LA_MAIN * Transform3D(Basis(), Vector3(0.0, 0.1, 0.0))
	_epee_main.visible = false
	_trainee = MeshInstance3D.new()
	_trainee.set_script(load("res://scripts/trainee.gd"))
	add_child(_trainee)


func _accrocher_epee(os: String) -> Node3D:
	var epee := Modeles.creer("Sword_Bronze", Modeles.OBJETS, arme.get("teinte", Color(0.6, 0.6, 0.7)))
	var attache := BoneAttachment3D.new()
	attache.bone_name = os
	_squelette.add_child(attache)
	attache.add_child(epee)
	return epee


## Sortir l'épée : la main va la chercher derrière l'épaule, puis le héros se met en garde.
func _degainer() -> void:
	_action = "degainer"
	_jouer_geste(ANIM_DEGAINER, MAIN_DANS_LE_DOS)
	Sons.jouer_apres(MAIN_DANS_LE_DOS * 0.7, "degainer", self)
	await get_tree().create_timer(MAIN_DANS_LE_DOS).timeout
	if _action != "degainer":
		return
	_epee_dos.visible = false
	_epee_main.visible = true
	epee_sortie = true
	_action = ""


## Ranger l'épée : le même geste à l'envers, l'épée retourne dans le dos.
func _ranger_epee() -> void:
	_action = "ranger"
	_jouer_geste(ANIM_DEGAINER, MAIN_DANS_LE_DOS, true)
	Sons.jouer("tissu", self)
	Sons.jouer_apres(0.1, "ranger", self)
	await get_tree().create_timer(0.08).timeout
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


# --- Animations -------------------------------------------------------------

## Joue un geste du haut du corps (coup, dégainer, coup reçu…) par-dessus les déplacements.
## « longueur » : ne jouer que le début de l'animation ; « a_l_envers » : la jouer à l'envers.
## Quand le héros est immobile, tout le corps fait le geste (plus beau) ;
## quand il court, seul le haut du corps le fait. « haut_en_courant » = false : tout le
## corps fait toujours le geste (par exemple le coup au sol après le bond).
## « vitesse » : plus de 1 accélère le geste.
func _jouer_geste(nom: String, longueur := 0.0, a_l_envers := false, haut_en_courant := true, debut := 0.0, vitesse := 1.0) -> void:
	_geste.animation = nom
	_arbre.set("parameters/geste_vitesse/scale", vitesse)
	_geste.use_custom_timeline = longueur > 0.0
	if longueur > 0.0:
		_geste.start_offset = debut
		_geste.timeline_length = longueur
		_geste.stretch_time_scale = false
	_geste.play_mode = AnimationNodeAnimation.PLAY_MODE_BACKWARD if a_l_envers else AnimationNodeAnimation.PLAY_MODE_FORWARD
	var en_mouvement := Vector2(velocity.x, velocity.z).length() > 0.5 or _direction_clavier().length() > 0.01
	_geste_unique.filter_enabled = en_mouvement and haut_en_courant
	_arbre.set("parameters/geste/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _arreter_geste() -> void:
	_action = ""
	_phase = ""
	_arbre.set("parameters/geste/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)


## Récupère les animations des Universal Animation Library 1 et 2 (même squelette, mêmes
## noms d'os ; celles du pack 2 commencent par « ual2/ »), puis construit l'arbre
## d'animation : le bas du corps suit les déplacements, et les gestes (coups, dégainer)
## se jouent par-dessus.
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
	if ResourceLoader.exists(MIXAMO):
		_anim.add_animation_library("mixamo", load(MIXAMO))
		_coups = COUPS_MIXAMO
		_bond = BOND_MIXAMO

	var racine := AnimationNodeBlendTree.new()
	var deplacement := AnimationNodeTransition.new()
	deplacement.xfade_time = 0.2
	racine.add_node("deplacement", deplacement)
	var i := 0
	for etat in ETATS:
		deplacement.add_input(etat)
		var animation := AnimationNodeAnimation.new()
		animation.animation = ETATS[etat]
		racine.add_node("anim_" + etat, animation)
		if etat == "roulade":
			racine.add_node("roulade_vitesse", AnimationNodeTimeScale.new())
			racine.connect_node("roulade_vitesse", 0, "anim_" + etat)
			racine.connect_node("deplacement", i, "roulade_vitesse")
		else:
			racine.connect_node("deplacement", i, "anim_" + etat)
		i += 1
	_geste_unique = AnimationNodeOneShot.new()
	_geste_unique.fadein_time = 0.08
	_geste_unique.fadeout_time = 0.2
	for os in OS_DU_HAUT:
		_geste_unique.set_filter_path(NodePath("Armature/Skeleton3D:" + os), true)
	racine.add_node("geste", _geste_unique)
	_geste = AnimationNodeAnimation.new()
	racine.add_node("geste_anim", _geste)
	_geste_vitesse = AnimationNodeTimeScale.new()
	racine.add_node("geste_vitesse", _geste_vitesse)
	racine.connect_node("geste_vitesse", 0, "geste_anim")
	racine.connect_node("geste", 0, "deplacement")
	racine.connect_node("geste", 1, "geste_vitesse")
	racine.connect_node("output", 0, "geste")

	_arbre = AnimationTree.new()
	_arbre.name = "Arbre"
	_modele.add_child(_arbre)
	_arbre.anim_player = NodePath("../Animations")
	_arbre.tree_root = racine
	_arbre.active = true
	_etat("repos")


func _bibliotheque(fichier: String) -> AnimationLibrary:
	var source := (load(fichier) as PackedScene).instantiate()
	var lecteur := source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var bibliotheque := lecteur.get_animation_library("")
	source.free()
	return bibliotheque


# --- Tête et cheveux --------------------------------------------------------

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
		_preparer_cheveux(maillage)
	cheveux.free()


func _deplacer_sur_le_heros(maillage: MeshInstance3D) -> void:
	maillage.get_parent().remove_child(maillage)
	maillage.owner = null
	_squelette.add_child(maillage)
	maillage.skeleton = NodePath("..")


## Les cheveux reçoivent un matériau spécial qui les allonge et les fait bouger.
func _preparer_cheveux(maillage: MeshInstance3D) -> void:
	var origine := maillage.mesh.surface_get_material(0) as StandardMaterial3D
	_cheveux = ShaderMaterial.new()
	_cheveux.shader = load("res://shaders/cheveux.gdshader")
	if origine:
		_cheveux.set_shader_parameter("texture_couleur", origine.albedo_texture)
	_cheveux.set_shader_parameter("teinte", couleur_cheveux)
	_cheveux.set_shader_parameter("allonge", longueur_cheveux)
	maillage.material_override = _cheveux
	# Les pointes allongées sortent de la boîte d'origine : on l'agrandit pour qu'elles
	# ne disparaissent pas au bord de l'écran.
	maillage.extra_cull_margin = 1.0


## Chaque image : où est la racine des cheveux, et comment les pointes suivent
## (avec un petit retard quand il court ou tourne, et un léger balancement au vent).
func _animer_cheveux(delta: float) -> void:
	if _cheveux == null or _os_tete < 0 or delta <= 0.0:
		return
	var tete := _squelette.get_bone_global_pose(_os_tete)
	var haut := tete.basis.y.normalized()
	# La racine : sous les oreilles (mesurée sur le modèle au repos).
	var repos := _squelette.get_bone_global_rest(_os_tete)
	var racine := tete.origin + haut * (1.62 - repos.origin.y)
	_cheveux.set_shader_parameter("racine", racine)
	_cheveux.set_shader_parameter("haut", haut)
	# Vitesse de la tête dans le monde, retardée : les cheveux « traînent » derrière.
	var tete_monde := _squelette.global_transform * tete.origin
	var vitesse := (tete_monde - _tete_avant) / delta
	_tete_avant = tete_monde
	if vitesse.length() > 30.0:
		vitesse = Vector3.ZERO
	_elan_cheveux = _elan_cheveux.lerp(-vitesse * 0.018, 1.0 - exp(-6.0 * delta))
	var vent := Vent.souffle(_temps, global_position) * 0.03 * (1.0 + sin(_temps * 2.1) * 0.4)
	var elan_monde := (_elan_cheveux + vent).limit_length(0.12)
	_cheveux.set_shader_parameter("elan", _modele.global_basis.inverse() * elan_monde)


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
		if maillage.material_override != null:
			continue
		# Sourcils noirs (demande de Tom), le reste teinté vers la palette.
		var couleur := couleur_cheveux if maillage.name == "Eyebrows" else teinte
		for i in maillage.mesh.get_surface_count():
			var mat := maillage.mesh.surface_get_material(i) as StandardMaterial3D
			if mat:
				var copie := mat.duplicate() as StandardMaterial3D
				copie.albedo_color = mat.albedo_color * couleur
				maillage.set_surface_override_material(i, copie)


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
