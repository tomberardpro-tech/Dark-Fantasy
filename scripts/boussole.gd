extends Control
## Petite boussole en haut de l'écran : une flèche qui indique la direction de Bruneval.
## Elle disparaît quand on arrive au hameau.

## À cette distance du hameau (en mètres), la boussole disparaît.
@export var distance_arrivee := 22.0

const RAYON := 18.0
const COULEUR_FOND := Color(0.027, 0.035, 0.102, 0.7)
const COULEUR_BORD := Color("5b6a9e")
const COULEUR_FLECHE := Color("f0ad55")
const COULEUR_TEXTE := Color("c3cde6")


func _ready() -> void:
	custom_minimum_size = Vector2(120, 64)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -60.0
	offset_right = 60.0
	offset_top = 8.0
	offset_bottom = 72.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	if joueur == null:
		return
	var vers_village := Chemin.VILLAGE - joueur.global_position
	vers_village.y = 0.0
	if vers_village.length() < distance_arrivee:
		return
	var camera := joueur.get_viewport().get_camera_3d()
	if camera == null:
		return
	# On projette la direction du hameau sur l'écran, pour que la flèche pointe
	# là où le joueur doit aller en regardant l'écran.
	var depart := camera.unproject_position(joueur.global_position)
	var arrivee := camera.unproject_position(joueur.global_position + vers_village.normalized() * 3.0)
	var direction := (arrivee - depart).normalized()
	var centre := Vector2(size.x / 2.0, RAYON + 2.0)
	draw_circle(centre, RAYON, COULEUR_FOND)
	draw_arc(centre, RAYON, 0.0, TAU, 32, COULEUR_BORD, 1.5)
	draw_colored_polygon(PackedVector2Array([
		centre + direction * (RAYON - 4.0),
		centre + direction.rotated(2.5) * 9.0,
		centre + direction.rotated(-2.5) * 9.0,
	]), COULEUR_FLECHE)
	var police := ThemeDB.fallback_font
	var texte := "Bruneval"
	var largeur := police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(police, Vector2(centre.x - largeur / 2.0, centre.y + RAYON + 16.0), texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COULEUR_TEXTE)
