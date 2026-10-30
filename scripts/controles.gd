extends Node
## Crée les touches du jeu au démarrage.
## Les touches de déplacement sont repérées par leur position sur le clavier :
## sur un clavier AZERTY ce sont Z Q S D, sur un clavier QWERTY W A S D.
## Les flèches marchent aussi.


func _ready() -> void:
	_ajouter("avancer", [KEY_W, KEY_UP])
	_ajouter("reculer", [KEY_S, KEY_DOWN])
	_ajouter("gauche", [KEY_A, KEY_LEFT])
	_ajouter("droite", [KEY_D, KEY_RIGHT])
	_ajouter("courir", [KEY_SHIFT])
	_ajouter("roulade", [KEY_SPACE])
	_ajouter("interagir", [KEY_E])
	_ajouter("degainer", [KEY_R])
	# Les potions : la touche A d'un clavier AZERTY (Q en QWERTY) ou 1 pour le soin, 2 pour la
	# force, 3 pour la résistance.
	_ajouter("potion_soin", [KEY_Q, KEY_1])
	_ajouter("potion_force", [KEY_2])
	_ajouter("potion_resistance", [KEY_3])
	# Raccourcis de travail, pour aller tout de suite à un endroit sans refaire le trajet
	# (voir joueur.gd, _raccourcis). Ce sont les lettres écrites sur les touches de Tom :
	# H le feu de départ, J l'entrée de Bruneval, K la place du village, L chez le chef,
	# M sur le chemin, juste avant les squelettes.
	_ajouter_lettre("aller_feu", KEY_H)
	_ajouter_lettre("aller_entree", KEY_J)
	_ajouter_lettre("aller_place", KEY_K)
	_ajouter_lettre("aller_chef", KEY_L)
	_ajouter_lettre("aller_squelettes", KEY_M)


## Une touche repérée par la lettre écrite dessus (et non par sa place sur le clavier).
func _ajouter_lettre(action: StringName, lettre: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var evenement := InputEventKey.new()
	evenement.keycode = lettre
	InputMap.action_add_event(action, evenement)


func _ajouter(action: StringName, touches: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for touche in touches:
		var evenement := InputEventKey.new()
		evenement.physical_keycode = touche
		InputMap.action_add_event(action, evenement)
