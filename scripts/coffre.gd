extends Node3D
## Un coffre en bois près du feu de la clairière (Fantasy Props MegaKit).
## Touche E à côté : il s'ouvre (son couvercle se soulève) et on y trouve la vieille épée.

## Distance à laquelle le message « E : ouvrir le coffre » apparaît.
@export var distance_interaction := 1.9

var ouvert := false
var _animations: AnimationPlayer


func _ready() -> void:
	add_to_group("interactif")
	var coffre := Modeles.creer("Chest_Wood")
	add_child(coffre)
	var lecteurs := coffre.find_children("*", "AnimationPlayer", true, false)
	if lecteurs.size() > 0:
		_animations = lecteurs[0]
	# Déjà ouvert si l'épée a été trouvée (et sauvegardée) dans une partie précédente.
	if Sauvegarde.donnee("epee", false):
		ouvert = true
		_ouvrir_couvercle(true)
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.3, 0.8, 0.8)
	var zone := CollisionShape3D.new()
	zone.shape = forme
	zone.position.y = 0.4
	var corps := StaticBody3D.new()
	corps.add_child(zone)
	add_child(corps)


## Utilisé par le joueur pour savoir s'il peut interagir avec le coffre.
func distance_pour_interagir(joueur: Node3D) -> float:
	if ouvert:
		return INF
	var d := joueur.global_position.distance_to(global_position)
	return d if d < distance_interaction else INF


func texte_interaction(_joueur: Node3D) -> String:
	return "E : ouvrir le coffre"


## L'ouverture : le coffre tremble (la serrure résiste), le couvercle se soulève
## lentement, une lueur dorée et une poussière brillante s'en échappent, puis l'épée
## s'élève en tournant avant de rejoindre le dos du héros.
func interagir(joueur: Node3D) -> void:
	ouvert = true
	Sons.jouer("loquet", global_position, -6.0)
	await _trembler()
	_ouvrir_couvercle(false)
	# Un grincement léger et grave : un vieux couvercle de bois.
	Sons.jouer("grincement", global_position, -4.0, 0.85)
	_allumer_lueur()
	await get_tree().create_timer(0.45).timeout
	await _elever_epee()
	joueur.prendre_epee()
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.notifier("Vous trouvez une vieille épée")


func _trembler() -> void:
	var modele := get_child(0) as Node3D
	var anim := create_tween()
	for i in 6:
		var cote := 1.0 if i % 2 == 0 else -1.0
		anim.tween_property(modele, "rotation:z", cote * 0.035 * (1.0 - i / 6.0), 0.05)
	anim.tween_property(modele, "rotation:z", 0.0, 0.05)
	await anim.finished


## Une lumière chaude qui monte de l'intérieur, et des grains de poussière dorée.
func _allumer_lueur() -> void:
	var lueur := OmniLight3D.new()
	lueur.light_color = Color("f2c46b")
	lueur.light_energy = 0.0
	lueur.omni_range = 3.0
	lueur.position.y = 0.7
	add_child(lueur)
	var anim := create_tween()
	anim.tween_property(lueur, "light_energy", 2.2, 0.5).set_ease(Tween.EASE_OUT)
	anim.tween_interval(1.2)
	anim.tween_property(lueur, "light_energy", 0.0, 1.5)
	anim.tween_callback(lueur.queue_free)

	var grain := SphereMesh.new()
	grain.radius = 0.015
	grain.height = 0.03
	grain.radial_segments = 4
	grain.rings = 2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("f7d58a")
	grain.material = mat
	var poussiere := CPUParticles3D.new()
	poussiere.mesh = grain
	poussiere.amount = 28
	poussiere.lifetime = 1.8
	poussiere.one_shot = true
	poussiere.explosiveness = 0.6
	poussiere.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	poussiere.emission_box_extents = Vector3(0.45, 0.05, 0.25)
	poussiere.direction = Vector3.UP
	poussiere.spread = 25.0
	poussiere.gravity = Vector3(0, 0.3, 0)
	poussiere.initial_velocity_min = 0.4
	poussiere.initial_velocity_max = 0.9
	poussiere.damping_min = 0.3
	poussiere.damping_max = 0.6
	poussiere.scale_amount_min = 0.6
	poussiere.scale_amount_max = 1.4
	poussiere.position.y = 0.6
	poussiere.emitting = true
	add_child(poussiere)
	get_tree().create_timer(2.5).timeout.connect(poussiere.queue_free)


## L'épée sort du coffre, monte en tournant lentement, puis s'efface.
## L'épée, couchée à l'horizontale comme si on la présentait, s'élève lentement du
## coffre en tournant doucement sur elle-même et en flottant un peu, puis s'efface.
func _elever_epee() -> void:
	var support := Node3D.new()
	support.position = Vector3(0, 0.45, 0)
	add_child(support)
	var epee := Modeles.creer("Sword_Bronze", Modeles.OBJETS, Color(0.6, 0.6, 0.7))
	# Le modèle est debout (lame vers le haut) : on le couche, centré sur le support.
	epee.basis = Basis(Vector3.BACK, PI / 2.0)
	epee.position = Vector3(0.42, 0, 0)
	support.add_child(epee)
	Sons.jouer("tintement", global_position + Vector3.UP)
	var anim := create_tween().set_parallel()
	anim.tween_property(support, "position:y", 1.2, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	anim.tween_property(support, "rotation:y", PI * 0.9, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Un léger balancement, comme portée par la lueur.
	anim.tween_property(support, "rotation:x", 0.08, 0.7).set_trans(Tween.TRANS_SINE)
	anim.chain().tween_property(support, "rotation:x", -0.06, 0.8).set_trans(Tween.TRANS_SINE)
	anim.chain().tween_property(support, "scale", Vector3.ONE * 0.01, 0.35).set_ease(Tween.EASE_IN)
	await anim.finished
	support.queue_free()


func _ouvrir_couvercle(tout_de_suite: bool) -> void:
	if _animations == null or _animations.get_animation_list().is_empty():
		return
	var nom: String = _animations.get_animation_list()[0]
	for n in _animations.get_animation_list():
		if n.to_lower().contains("open"):
			nom = n
	# Le couvercle se soulève plus lentement que dans le modèle d'origine (plus lourd).
	_animations.play(nom, -1, 0.55)
	if tout_de_suite:
		_animations.seek(_animations.current_animation_length, true)
