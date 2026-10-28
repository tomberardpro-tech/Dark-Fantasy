extends Node
## La musique douce de la clairière (« Lament for a Warrior's Soul », RandomMind, CC0).
## Elle joue en boucle près du feu et s'éteint doucement quand on s'éloigne.

## Jusqu'à cette distance du feu (en mètres), la musique joue à plein volume.
@export var distance_pleine := 14.0
## À partir de cette distance, on ne l'entend plus.
@export var distance_silence := 45.0
## Volume maximum (en décibels : 0 = normal, plus négatif = plus doux).
@export var volume_max_db := -8.0
@export var centre := Vector3.ZERO

const FICHIER := "res://assets/musique/Lament_for_a_Warriors_Soul.mp3"

var _lecteur: AudioStreamPlayer


func _ready() -> void:
	var flux := load(FICHIER) as AudioStreamMP3
	if flux == null:
		return
	flux.loop = true
	_lecteur = AudioStreamPlayer.new()
	_lecteur.stream = flux
	_lecteur.volume_db = -80.0
	add_child(_lecteur)
	_lecteur.play()


func _process(delta: float) -> void:
	if _lecteur == null:
		return
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	if joueur == null:
		return
	var d := Vector2(joueur.global_position.x - centre.x, joueur.global_position.z - centre.z).length()
	var force := 1.0 - smoothstep(distance_pleine, distance_silence, d)
	var cible := linear_to_db(max(force, 0.0001)) + volume_max_db
	# Le volume change en douceur.
	_lecteur.volume_db = lerpf(_lecteur.volume_db, cible, 1.0 - exp(-2.0 * delta))
