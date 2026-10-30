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
	_habiller_d_ecorce()
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
	# Pas de message tant que la sauvegarde sur le disque est coupée (voir sauvegarde.gd).
	if interface and Sauvegarde.SUR_LE_DISQUE:
		interface.notifier("Partie sauvegardée")


## Le tronc couché du pack Quaternius Ultimate Nature (« WoodLog », choix de Tom), un peu
## réduit pour que le héros s'assoie à la bonne hauteur, et assombri pour la nuit.
## Il remplace la forme simple du nœud « Apparence » (gardée cachée dans la scène).
const MODELE := "res://assets/nature/WoodLog.fbx"
const ECHELLE := 0.7


func _habiller_d_ecorce() -> void:
	var apparence := get_node_or_null("Apparence") as MeshInstance3D
	if apparence:
		apparence.visible = false
	var tronc := (load(MODELE) as PackedScene).instantiate() as Node3D
	tronc.name = "Tronc couché"
	Modeles.teinter(tronc, Color(0.85, 0.78, 0.76))
	add_child(tronc)
	# Le modèle est couché le long de son Z : on le tourne pour qu'il suive le X du tronc,
	# puis on le centre (son milieu sur le point du tronc, posé au sol).
	tronc.rotation.y = PI / 2.0
	tronc.scale = Vector3.ONE * ECHELLE
	var boite := AABB()
	var premier := true
	for m in tronc.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (global_transform.affine_inverse() * m.global_transform) * (m as MeshInstance3D).get_aabb()
		boite = b if premier else boite.merge(b)
		premier = false
	var milieu := boite.get_center()
	tronc.position = Vector3(-milieu.x, -boite.position.y, -milieu.z)


## Vrai si c'est ici que le héros doit se réveiller (dernier feu utilisé, ou feu de départ).
func est_le_dernier_feu() -> bool:
	if Sauvegarde.existe():
		return Sauvegarde.dernier_feu() == nom_du_feu
	return feu_de_depart


## Après sa mort, le héros se réveille assis ici.
func reveiller_au_feu(joueur: Node3D) -> void:
	joueur.asseoir(point_assise(), regard(), true, self)


## L'endroit où se place le personnage assis : juste devant le tronc, côté feu.
func point_assise() -> Vector3:
	return global_transform * Vector3(0.0, 0.0, 0.65)


## La direction du regard du personnage assis : vers le feu.
func regard() -> Vector3:
	return global_basis.z.normalized()
