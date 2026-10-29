extends Control
## L'indicateur de destination, en haut de l'écran : le nom du lieu à rejoindre entre deux
## fins traits terminés par un losange, et dessous un petit chevron qui pointe vers lui
## (direction vue à l'écran). Discret et un peu transparent ; il s'efface à l'arrivée.

## Le lieu à rejoindre et son nom.
@export var destination := Vector3.ZERO
@export var nom := "Bruneval"
## En dessous de cette distance (en mètres), l'indicateur disparaît.
@export var distance_arrivee := 16.0

const COULEUR := Color(0.76, 0.8, 0.9, 0.7)
const COULEUR_ORNEMENT := Color(0.55, 0.42, 0.28, 0.65)

var _angle := 0.0
var _opacite := 0.0
var _police: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_police = load("res://assets/polices/Cinzel.ttf")
	destination = Chemin.VILLAGE


func _process(delta: float) -> void:
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	var camera := joueur.get_viewport().get_camera_3d() if joueur else null
	var visible_voulu := 0.0
	if joueur and camera:
		var ici := camera.unproject_position(joueur.global_position)
		var la := camera.unproject_position(destination)
		var vers := la - ici
		if vers.length() > 1.0:
			_angle = lerp_angle(_angle, vers.angle(), 1.0 - exp(-6.0 * delta))
		var loin := joueur.global_position.distance_to(destination) > distance_arrivee
		visible_voulu = 1.0 if loin and not joueur.est_assis else 0.0
	_opacite = move_toward(_opacite, visible_voulu, delta * 0.8)
	queue_redraw()


func _draw() -> void:
	if _opacite <= 0.01:
		return
	var centre := Vector2(size.x / 2.0, 34.0)
	var taille_texte := 15
	var largeur := _police.get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_texte).x
	var couleur := Color(COULEUR, COULEUR.a * _opacite)
	var ornement := Color(COULEUR_ORNEMENT, COULEUR_ORNEMENT.a * _opacite)
	draw_string(_police, centre + Vector2(-largeur / 2.0, 5.0), nom, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_texte, couleur)
	# Les deux traits, terminés par un petit losange.
	for cote in [-1.0, 1.0]:
		var debut := centre + Vector2(cote * (largeur / 2.0 + 10.0), 0.0)
		var fin := debut + Vector2(cote * 46.0, 0.0)
		draw_line(debut, fin, ornement, 1.0, true)
		var l := fin + Vector2(cote * 4.0, 0.0)
		draw_colored_polygon(PackedVector2Array([l + Vector2(0, -3), l + Vector2(cote * 4.0, 0), l + Vector2(0, 3), l + Vector2(-cote * 4.0, 0)]), ornement)
	# Le chevron, sous le nom, tourné vers la destination.
	var pointe := centre + Vector2(0, 24.0)
	var avant := Vector2.from_angle(_angle)
	var cote_chevron := avant.orthogonal()
	var bout := pointe + avant * 6.0
	draw_polyline(PackedVector2Array([bout - avant * 8.0 + cote_chevron * 6.0, bout, bout - avant * 8.0 - cote_chevron * 6.0]), couleur, 1.5, true)
