extends Node3D
## Trois squelettes allongés au bord du chemin, juste après le pont.
## Ils se relèvent quand le héros approche (voir squelette.gd).

## À quelle distance après le pont (le long du chemin) se trouve chaque squelette,
## de quel côté du chemin, et avec quel modèle et quelle arme.
const SQUELETTES := [
	{"apres_le_pont": 9.0, "cote": 2.6, "modele": "Skeleton_Minion", "arme": "Skeleton_Blade"},
	{"apres_le_pont": 13.0, "cote": -2.8, "modele": "Skeleton_Warrior", "arme": "Skeleton_Axe"},
	{"apres_le_pont": 17.0, "cote": 2.4, "modele": "Skeleton_Rogue", "arme": "Skeleton_Blade"},
]


func _ready() -> void:
	var courbe: Curve3D = Chemin.courbe_chemin
	var au_pont := courbe.get_closest_offset(Chemin.PONT)
	for s in SQUELETTES:
		var d: float = au_pont + s["apres_le_pont"]
		var p := courbe.sample_baked(d)
		var tangente := (courbe.sample_baked(d + 1.0) - courbe.sample_baked(d - 1.0)).normalized()
		var cote := Vector3(-tangente.z, 0.0, tangente.x)
		var squelette := CharacterBody3D.new()
		squelette.set_script(load("res://scripts/squelette.gd"))
		squelette.modele = s["modele"]
		squelette.arme = s["arme"]
		squelette.position = p + cote * s["cote"]
		add_child(squelette)
