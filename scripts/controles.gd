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


func _ajouter(action: StringName, touches: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for touche in touches:
		var evenement := InputEventKey.new()
		evenement.physical_keycode = touche
		InputMap.action_add_event(action, evenement)
