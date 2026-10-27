extends Node3D
## Une charrette renversée au bord du chemin, avec des caisses éparpillées.
## Touche E à côté : on la fouille et on y trouve une vieille épée (la première arme).

## Distance à laquelle le message « E : fouiller la charrette » apparaît.
@export var distance_interaction := 3.2

var fouillee := false


func _ready() -> void:
	add_to_group("interactif")
	fouillee = Sauvegarde.donnee("epee", false)
	_construire()


## Utilisé par le joueur pour savoir s'il peut interagir avec la charrette.
func distance_pour_interagir(joueur: Node3D) -> float:
	if fouillee:
		return INF
	var d := joueur.global_position.distance_to(global_position)
	return d if d < distance_interaction else INF


func texte_interaction(_joueur: Node3D) -> String:
	return "E : fouiller la charrette"


func interagir(joueur: Node3D) -> void:
	fouillee = true
	joueur.prendre_epee()
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.notifier("Vous trouvez une vieille épée")


func _construire() -> void:
	# La charrette du pack (4 m de long), couchée sur le côté.
	var support := Node3D.new()
	support.rotation.y = 0.3
	add_child(support)
	var charrette := Modeles.creer("Prop_Wagon")
	# Le modèle va de z = -3.15 à +0.87 : on le recentre, puis on le bascule.
	charrette.basis = Basis(Vector3.BACK, 1.45)
	charrette.position = Vector3(0.75, 0.95, 1.14)
	support.add_child(charrette)
	# Son chargement, éparpillé sur le sol.
	for o in [["Barrel", Vector3(-1.4, 0, 1.6), Vector3(PI / 2.0, 0.4, 0)],
			["Crate_Wooden", Vector3(1.6, 0, 1.2), Vector3(0, 0.6, 0)],
			["Crate_Wooden", Vector3(1.9, 0, -0.2), Vector3(0, 1.2, 0.15)],
			["Bag", Vector3(-1.3, 0, -1.0), Vector3(0, 2.0, 0)]]:
		var objet := Modeles.creer(o[0])
		objet.position = o[1] + (Vector3(0, 0.35, 0) if o[0] == "Barrel" else Vector3.ZERO)
		objet.rotation = o[2]
		support.add_child(objet)
	var forme := BoxShape3D.new()
	forme.size = Vector3(1.8, 1.8, 4.0)
	var zone := CollisionShape3D.new()
	zone.shape = forme
	zone.position = Vector3(0, 0.9, 0)
	var corps := StaticBody3D.new()
	corps.add_child(zone)
	support.add_child(corps)
