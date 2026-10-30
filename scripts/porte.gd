extends Node3D
## Une porte qu'on passe avec E, comme dans Pokémon : l'écran s'assombrit, et le héros se
## retrouve de l'autre côté (dans une pièce à part, ou dehors devant la maison).

@export var texte := "E : entrer"
## Où le héros arrive, et vers où il regarde en arrivant.
@export var arrivee := Vector3.ZERO
@export var regard := Vector3.FORWARD
## Vrai si l'on entre dans une pièce (on cache alors les lucioles et les feuilles).
@export var vers_l_interieur := true
@export var portee := 1.4


func _ready() -> void:
	add_to_group("interactif")


func distance_pour_interagir(joueur: Node3D) -> float:
	var d := Vector2(joueur.global_position.x - global_position.x, joueur.global_position.z - global_position.z).length()
	return d if d < portee else INF


func texte_interaction(_joueur: Node3D) -> String:
	return texte


func interagir(joueur: Node3D) -> void:
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.passer_la_porte(joueur, arrivee, regard, vers_l_interieur)
