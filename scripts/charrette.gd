extends Node3D
## Une charrette renversée au bord du chemin, avec des caisses éparpillées.
## Touche E à côté : on la fouille et on y trouve une vieille épée (la première arme).

## Distance à laquelle le message « E : fouiller la charrette » apparaît.
@export var distance_interaction := 2.6

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
	var bois := StandardMaterial3D.new()
	bois.albedo_color = Color("4a3b31")
	bois.roughness = 1.0
	var bois_sombre := StandardMaterial3D.new()
	bois_sombre.albedo_color = Color("2a221f")
	bois_sombre.roughness = 1.0
	# La caisse de la charrette, couchée sur le côté.
	var caisse := _boite(Vector3(2.2, 0.7, 1.3), bois)
	caisse.position = Vector3(0, 0.65, 0)
	caisse.rotation = Vector3(0.0, 0.3, 1.25)
	add_child(caisse)
	# Une roue encore attachée, une autre tombée par terre.
	var roue := _roue(bois_sombre)
	roue.position = Vector3(0.3, 1.3, 0.75)
	roue.rotation = Vector3(PI / 2.0, 0.3, 0.0)
	add_child(roue)
	var roue_tombee := _roue(bois_sombre)
	roue_tombee.position = Vector3(-1.8, 0.06, 1.3)
	add_child(roue_tombee)
	# Le timon et quelques caisses éparpillées.
	var timon := _boite(Vector3(2.0, 0.1, 0.1), bois_sombre)
	timon.position = Vector3(1.9, 0.08, -0.4)
	timon.rotation.y = 0.5
	add_child(timon)
	for i in 3:
		var petite := _boite(Vector3(0.45, 0.4, 0.45), bois)
		petite.position = Vector3(-1.2 + i * 0.6, 0.2, -1.1 - (i % 2) * 0.4)
		petite.rotation.y = i * 0.7
		add_child(petite)
	var forme := BoxShape3D.new()
	forme.size = Vector3(2.3, 1.6, 1.6)
	var zone := CollisionShape3D.new()
	zone.shape = forme
	zone.position = Vector3(0, 0.8, 0)
	zone.rotation.y = 0.3
	var corps := StaticBody3D.new()
	corps.add_child(zone)
	add_child(corps)


func _roue(mat: Material) -> MeshInstance3D:
	var forme := CylinderMesh.new()
	forme.top_radius = 0.45
	forme.bottom_radius = 0.45
	forme.height = 0.1
	forme.radial_segments = 10
	var roue := MeshInstance3D.new()
	roue.mesh = forme
	roue.material_override = mat
	return roue


func _boite(taille: Vector3, mat: Material) -> MeshInstance3D:
	var forme := BoxMesh.new()
	forme.size = taille
	var objet := MeshInstance3D.new()
	objet.mesh = forme
	objet.material_override = mat
	return objet
