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


func _ready() -> void:
	add_to_group("interactif")
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur == null:
		return
	var reprendre_ici: bool = Sauvegarde.dernier_feu() == nom_du_feu
	var nouvelle_partie: bool = not Sauvegarde.existe() and feu_de_depart and joueur.assis_au_depart
	if reprendre_ici or nouvelle_partie:
		joueur.asseoir.call_deferred(point_assise(), regard(), true, self)


## Utilisé par le joueur pour savoir s'il peut interagir avec ce tronc.
func distance_pour_interagir(joueur: Node3D) -> float:
	if joueur.est_assis:
		return 0.0 if joueur.siege == self else INF
	var d := joueur.global_position.distance_to(point_assise())
	return d if d < distance_interaction else INF


func texte_interaction(joueur: Node3D) -> String:
	return "E : se relever" if joueur.est_assis else "E : s'asseoir"


func interagir(joueur: Node3D) -> void:
	if joueur.est_assis:
		joueur.se_relever()
		return
	joueur.asseoir(point_assise(), regard(), false, self)
	Sauvegarde.sauvegarder(nom_du_feu, point_assise(), {"epee": joueur.a_epee})
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.notifier("Partie sauvegardée")


## L'endroit où se place le personnage assis : juste devant le tronc, côté feu.
func point_assise() -> Vector3:
	return global_transform * Vector3(0.0, 0.0, 0.65)


## La direction du regard du personnage assis : vers le feu.
func regard() -> Vector3:
	return global_basis.z.normalized()
