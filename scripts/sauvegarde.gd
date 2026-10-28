extends Node
## Sauvegarde de la partie, uniquement aux feux de camp.
## On retient le dernier feu de camp où le joueur s'est assis, sa position à ce
## moment-là, et ce qu'il a trouvé (par exemple la vieille épée).
## Le fichier est rangé par Godot dans le dossier des données du jeu
## (%APPDATA%\Godot\app_userdata\Jeu Dark Fantasy\sauvegarde.json).

const FICHIER := "user://sauvegarde.json"
## Pendant la fabrication du jeu, Tom veut repartir de zéro à chaque lancement pour voir
## ses modifications : on n'écrit ni ne relit rien sur le disque. La partie est quand même
## retenue pendant qu'on joue (pour se réveiller au dernier feu après une mort).
## Mettre à true pour réactiver la vraie sauvegarde.
const SUR_LE_DISQUE := false

var _donnees := {}


func _ready() -> void:
	if SUR_LE_DISQUE:
		charger()
	else:
		effacer()


## Enregistre la partie au feu de camp « feu » (son nom), le joueur étant à « position ».
## « autres » : d'autres choses à retenir, par exemple {"epee": true}.
func sauvegarder(feu: String, position: Vector3, autres := {}) -> void:
	_donnees = {
		"feu": feu,
		"position": [position.x, position.y, position.z],
		"date": Time.get_datetime_string_from_system(),
	}
	_donnees.merge(autres)
	if not SUR_LE_DISQUE:
		return
	var fichier := FileAccess.open(FICHIER, FileAccess.WRITE)
	if fichier:
		fichier.store_string(JSON.stringify(_donnees, "\t"))


func charger() -> void:
	_donnees = {}
	if not FileAccess.file_exists(FICHIER):
		return
	var resultat: Variant = JSON.parse_string(FileAccess.get_file_as_string(FICHIER))
	if resultat is Dictionary:
		_donnees = resultat


## Le nom du dernier feu de camp utilisé, ou "" s'il n'y a pas encore de sauvegarde.
func dernier_feu() -> String:
	return _donnees.get("feu", "")


## Une information sauvegardée (par exemple "epee"), ou « defaut » si elle n'existe pas.
func donnee(cle: String, defaut: Variant = null) -> Variant:
	return _donnees.get(cle, defaut)


func existe() -> bool:
	return not dernier_feu().is_empty()


## Efface la sauvegarde (pour recommencer une partie neuve).
func effacer() -> void:
	_donnees = {}
	if FileAccess.file_exists(FICHIER):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FICHIER))
