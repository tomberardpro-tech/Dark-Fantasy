extends Node
## La musique douce de la zone de départ (« Lament for a Warrior's Soul », RandomMind, CC0).
## Elle joue partout, au même volume, et tourne en boucle sans trou : quelques secondes
## avant la fin du morceau, un deuxième lecteur le reprend au début pendant que le premier
## s'éteint (le morceau finit par un fondu, qu'on ne laisse jamais aller jusqu'au silence).

## Volume (en décibels : 0 = normal, plus négatif = plus doux).
@export var volume_max_db := -15.0
## Durée du passage d'une boucle à la suivante (en secondes).
@export var fondu := 8.0

const FICHIER := "res://assets/musique/Lament_for_a_Warriors_Soul.mp3"

var _lecteurs: Array[AudioStreamPlayer] = []
## Le lecteur qui joue le morceau en ce moment (l'autre s'éteint ou attend).
var _actuel := 0
var _longueur := 0.0


func _ready() -> void:
	var flux := load(FICHIER) as AudioStreamMP3
	if flux == null:
		return
	flux.loop = false
	_longueur = flux.get_length()
	for i in 2:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -80.0
		add_child(lecteur)
		_lecteurs.append(lecteur)
	_lecteurs[0].play()


func _process(delta: float) -> void:
	if _lecteurs.is_empty():
		return
	var actuel := _lecteurs[_actuel]
	var autre := _lecteurs[1 - _actuel]
	# Bientôt la fin : l'autre lecteur reprend le morceau au début.
	if actuel.playing and actuel.get_playback_position() > _longueur - fondu:
		autre.volume_db = -80.0
		autre.play()
		_actuel = 1 - _actuel
		actuel = _lecteurs[_actuel]
		autre = _lecteurs[1 - _actuel]
	# Celui qui joue monte au volume voulu, l'autre s'éteint ; tout en douceur.
	var vitesse := 1.0 - exp(-4.0 / fondu * delta)
	actuel.volume_db = lerpf(actuel.volume_db, volume_max_db, vitesse)
	if autre.playing:
		autre.volume_db = lerpf(autre.volume_db, -80.0, vitesse)
		if autre.volume_db < -60.0:
			autre.stop()
