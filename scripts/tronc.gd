extends StaticBody3D
## Tronc près du feu. Touche E à côté : s'asseoir ou se relever.
## Au lancement du jeu, le personnage y est déjà assis, face au feu.

## Distance à laquelle le message « E : s'asseoir » apparaît.
@export var distance_interaction := 1.8

var _joueur: Node
var _interface: Node


func _ready() -> void:
	_joueur = get_tree().get_first_node_in_group("joueur")
	_interface = get_tree().get_first_node_in_group("interface")
	if _joueur and _joueur.assis_au_depart:
		_joueur.asseoir.call_deferred(point_assise(), regard(), true)


func _process(_delta: float) -> void:
	if _joueur == null or _interface == null:
		return
	if Input.is_action_just_pressed("interagir"):
		if _joueur.est_assis:
			_joueur.se_relever()
		elif _est_proche():
			_joueur.asseoir(point_assise(), regard())
	if _joueur.est_assis:
		_interface.afficher("E : se relever")
	elif _est_proche():
		_interface.afficher("E : s'asseoir")
	else:
		_interface.cacher()


## L'endroit où se place le personnage assis : juste devant le tronc, côté feu.
func point_assise() -> Vector3:
	return global_transform * Vector3(0.0, 0.0, 0.65)


## La direction du regard du personnage assis : vers le feu.
func regard() -> Vector3:
	return global_basis.z.normalized()


func _est_proche() -> bool:
	return _joueur.global_position.distance_to(point_assise()) < distance_interaction
