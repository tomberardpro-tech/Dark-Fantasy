extends StaticBody3D
## Tronc près d'un feu de camp. Touche E à côté : s'asseoir ou se relever.
## S'asseoir au feu sauvegarde la partie (voir sauvegarde.gd).
## Au lancement, le personnage est assis au dernier feu utilisé, ou au feu de départ
## s'il n'y a pas encore de sauvegarde.

## Nom unique de ce feu de camp, utilisé dans la sauvegarde.
@export var nom_du_feu := "clairiere"
## Est-ce le feu où commence une nouvelle partie ?
@export var feu_de_depart := true
## Distance à laquelle le message « E : s'asseoir » apparaît.
@export var distance_interaction := 1.8

var _joueur: Node
var _interface: Node


func _ready() -> void:
	_joueur = get_tree().get_first_node_in_group("joueur")
	_interface = get_tree().get_first_node_in_group("interface")
	if _joueur == null:
		return
	var reprendre_ici := Sauvegarde.dernier_feu() == nom_du_feu
	var nouvelle_partie: bool = not Sauvegarde.existe() and feu_de_depart and _joueur.assis_au_depart
	if reprendre_ici or nouvelle_partie:
		_joueur.asseoir.call_deferred(point_assise(), regard(), true)


func _process(_delta: float) -> void:
	if _joueur == null or _interface == null:
		return
	if Input.is_action_just_pressed("interagir"):
		if _joueur.est_assis:
			_joueur.se_relever()
		elif _est_proche():
			_joueur.asseoir(point_assise(), regard())
			Sauvegarde.sauvegarder(nom_du_feu, point_assise())
			_interface.notifier("Partie sauvegardée")
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
