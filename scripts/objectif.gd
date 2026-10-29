extends Control
## Le repère de direction, en haut de l'écran : un fin trait orné avec un losange au
## centre, et dessous un petit chevron qui pointe vers la destination (direction vue à
## l'écran). Aucun nom : on découvre le lieu en arrivant, et alors son nom apparaît en
## grand (voir interface.gd, annoncer_lieu). Discret et un peu transparent.

## Le lieu à rejoindre, et le nom révélé à l'arrivée.
@export var destination := Vector3.ZERO
@export var nom := "Bruneval"
## En dessous de cette distance (en mètres), on est arrivé.
@export var distance_arrivee := 16.0

const COULEUR := Color(0.76, 0.8, 0.9, 0.7)
const COULEUR_ORNEMENT := Color(0.55, 0.42, 0.28, 0.65)

var _angle := 0.0
var _opacite := 0.0
var _arrive := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		if not loin and not _arrive:
			_arrive = true
			var interface := get_tree().get_first_node_in_group("interface")
			if interface:
				interface.annoncer_lieu(nom)
		visible_voulu = 1.0 if loin and not _arrive and not joueur.est_assis else 0.0
	_opacite = move_toward(_opacite, visible_voulu, delta * 0.8)
	queue_redraw()


func _draw() -> void:
	if _opacite <= 0.01:
		return
	var centre := Vector2(size.x / 2.0, 30.0)
	var couleur := Color(COULEUR, COULEUR.a * _opacite)
	var ornement := Color(COULEUR_ORNEMENT, COULEUR_ORNEMENT.a * _opacite)
	# Le trait, interrompu au centre par un losange, et terminé par deux petits losanges.
	for cote in [-1.0, 1.0]:
		draw_line(centre + Vector2(cote * 12.0, 0.0), centre + Vector2(cote * 70.0, 0.0), ornement, 1.0, true)
		_losange(centre + Vector2(cote * 75.0, 0.0), 3.0, ornement)
	_losange(centre, 5.0, couleur)
	# Le chevron, dessous, tourné vers la destination.
	var avant := Vector2.from_angle(_angle)
	var cote_chevron := avant.orthogonal()
	var bout := centre + Vector2(0, 20.0) + avant * 6.0
	draw_polyline(PackedVector2Array([bout - avant * 8.0 + cote_chevron * 6.0, bout, bout - avant * 8.0 - cote_chevron * 6.0]), couleur, 1.5, true)


func _losange(centre: Vector2, taille: float, couleur: Color) -> void:
	draw_colored_polygon(PackedVector2Array([centre + Vector2(0, -taille), centre + Vector2(taille, 0),
		centre + Vector2(0, taille), centre + Vector2(-taille, 0)]), couleur)
