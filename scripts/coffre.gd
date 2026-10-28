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


func interagir(joueur: Node3D) -> void:
	ouvert = true
	_ouvrir_couvercle(false)
	joueur.prendre_epee()
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.notifier("Vous trouvez une vieille épée")


func _ouvrir_couvercle(tout_de_suite: bool) -> void:
	if _animations == null or _animations.get_animation_list().is_empty():
		return
	var nom: String = _animations.get_animation_list()[0]
	for n in _animations.get_animation_list():
		if n.to_lower().contains("open"):
			nom = n
	_animations.play(nom)
	if tout_de_suite:
		_animations.seek(_animations.current_animation_length, true)
