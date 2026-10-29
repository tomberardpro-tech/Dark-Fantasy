extends Node3D
## Une petite cabane de 4 m sur 2, juste avant Bruneval (pièces du Medieval Village et du
## Fantasy Props MegaKit). Le fond est vers le haut de l'écran, le côté vers la caméra est
## ouvert (on voit l'intérieur), la porte donne sur le chemin, et la moitié du toit est
## tombée. Dedans : une table d'écrivain avec une bougie, des livres, un parchemin, et la
## lettre de Maren qui brille (voir lettre.gd).

## Le texte de la lettre (Tom peut le changer ici).
const TITRE := "Une lettre laissée sur la table"
const TEXTE := """Aldric,

Je t'écris en hâte, et ma main tremble encore.

Ce que les anciens murmuraient est arrivé. Un dieu s'est détourné de nous et a jeté sa malédiction sur le monde. Le soleil ne s'est plus levé depuis trois jours, et les morts ne restent plus sous la terre.

Des choses sont apparues dans la forêt. J'ai vu des os marcher près du ruisseau, et l'autel du chemin saigne d'une lueur rouge.

Ne reste pas ici. Pars avant que les routes se ferment et va chercher ta fille, vite. Elle est seule là où tu l'as laissée, et chaque nuit qui passe la met un peu plus en danger.

Ne t'arrête pas en chemin. Ne fais confiance à rien de ce qui marche dans le noir."""
const SIGNATURE := "Que ce qui reste de lumière te garde.\n— Maren"


func _ready() -> void:
	position = Chemin.ABRI
	rotation.y = Chemin.ROTATION_ABRI
	_construire_cabane()
	_meubler()


func _construire_cabane() -> void:
	# [modèle, position, tourné d'un quart de tour] : deux murs au fond, un de chaque côté
	# (celui vers le chemin a la porte), rien du côté de la caméra.
	var murs := [
		["Wall_Plaster_Straight", Vector3(-1, 0, -1), false],
		["Wall_Plaster_WoodGrid", Vector3(1, 0, -1), false],
		["Wall_Plaster_Door_Flat", Vector3(-2, 0, 0), true],
		["Wall_Plaster_Window_Wide_Flat", Vector3(2, 0, 0), true],
	]
	for m in murs:
		var mur := Modeles.creer(m[0])
		mur.position = m[1]
		if m[2]:
			mur.rotation.y = PI / 2.0
		add_child(mur)
		var forme := BoxShape3D.new()
		forme.size = Vector3(2.0, 3.0, 0.3)
		# La porte reste franchissable : on ne bloque que les côtés de son mur.
		if m[0] == "Wall_Plaster_Door_Flat":
			for bout in [-0.75, 0.75]:
				var morceau := BoxShape3D.new()
				morceau.size = Vector3(0.5, 3.0, 0.3)
				_obstacle(morceau, Transform3D(mur.basis, m[1] + mur.basis * Vector3(bout, 1.5, 0)))
			continue
		_obstacle(forme, Transform3D(mur.basis, m[1] + Vector3(0, 1.5, 0)))
	for coin in [Vector3(-2, 0, -1), Vector3(2, 0, -1), Vector3(-2, 0, 1), Vector3(2, 0, 1)]:
		var poteau := Modeles.creer("Corner_Exterior_Wood")
		poteau.position = coin
		add_child(poteau)
	for x in [-1.0, 1.0]:
		var plancher := Modeles.creer("Floor_WoodDark")
		plancher.position = Vector3(x, 0.02, 0)
		add_child(plancher)
	# Le toit ne tient plus qu'au-dessus de la moitié droite : on voit la table d'en haut.
	var toit := Modeles.creer("Roof_Wooden_2x1_Middle")
	toit.position = Vector3(1, 2.2, 0)
	add_child(toit)
	var tombe := Modeles.creer("Roof_Wooden_2x1_Middle")
	tombe.position = Vector3(-1.1, 0.6, 1.6)
	tombe.basis = Basis(Vector3.RIGHT, 0.5) * Basis(Vector3.UP, 0.2)
	add_child(tombe)
	var lierre := Modeles.creer("Prop_Vine1", Modeles.OBJETS, Color(0.42, 0.5, 0.52))
	lierre.position = Vector3(1.0, 2.9, -1.2)
	add_child(lierre)


func _meubler() -> void:
	# La grande table du pack, raccourcie en table d'écrivain (1,6 m sur 0,7), contre le fond.
	var table := Modeles.creer("Table_Large")
	table.position = Vector3(-0.6, 0.02, -0.45)
	table.scale = Vector3(0.55, 1.0, 0.65)
	add_child(table)
	var forme_table := BoxShape3D.new()
	forme_table.size = Vector3(1.6, 0.8, 0.7)
	_obstacle(forme_table, Transform3D(Basis(), Vector3(-0.6, 0.42, -0.45)))
	var chaise := Modeles.creer("Chair_1")
	chaise.position = Vector3(-0.35, 0.02, 0.35)
	chaise.rotation.y = PI + 0.35
	add_child(chaise)
	var dessus := 0.83
	for o in [["CandleStick", Vector3(-1.2, dessus, -0.6), 0.3], ["Book_Stack_1", Vector3(0.0, dessus, -0.62), -0.4],
			["Scroll_1", Vector3(-0.15, dessus, -0.3), 1.1]]:
		var objet := Modeles.creer(o[0])
		objet.position = o[1]
		objet.rotation.y = o[2]
		add_child(objet)
	var bougie := Modeles.creer("Candle_1")
	bougie.position = Vector3(-1.2, dessus + 0.05, -0.6)
	add_child(bougie)
	var flamme := MeshInstance3D.new()
	var goutte := SphereMesh.new()
	goutte.radius = 0.018
	goutte.height = 0.05
	flamme.mesh = goutte
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffd38a")
	flamme.material_override = mat
	flamme.position = bougie.position + Vector3(0, 0.16, 0)
	add_child(flamme)
	var lumiere := OmniLight3D.new()
	lumiere.light_color = Color("f0ad55")
	lumiere.light_energy = 0.9
	lumiere.omni_range = 3.5
	lumiere.position = flamme.position + Vector3(0, 0.1, 0)
	add_child(lumiere)
	# La lettre, posée de travers devant la chaise.
	var lettre := Node3D.new()
	lettre.set_script(load("res://scripts/lettre.gd"))
	lettre.titre = TITRE
	lettre.texte = TEXTE
	lettre.signature = SIGNATURE
	lettre.position = Vector3(-0.55, dessus + 0.005, -0.38)
	lettre.rotation.y = 0.25
	add_child(lettre)


func _obstacle(forme: Shape3D, transfo: Transform3D) -> void:
	var zone := CollisionShape3D.new()
	zone.shape = forme
	var corps := StaticBody3D.new()
	corps.transform = transfo
	corps.add_child(zone)
	add_child(corps)
