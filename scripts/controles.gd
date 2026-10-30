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


func _ajouter(action: StringName, touches: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for touche in touches:
		var evenement := InputEventKey.new()
		evenement.physical_keycode = touche
		InputMap.action_add_event(action, evenement)
