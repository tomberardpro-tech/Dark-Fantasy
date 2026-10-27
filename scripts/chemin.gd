extends Node
## Le plan de la zone de départ : le tracé du chemin de la clairière jusqu'à Bruneval,
## le ruisseau, et l'emplacement des lieux à découvrir en route.
## Les autres scripts lui demandent par exemple « suis-je loin du chemin ? »
## (pour ne pas planter d'arbre au milieu).

## Les points de passage du sentier, de la clairière jusqu'à l'entrée de Bruneval.
## Avec la caméra du jeu, le chemin part vers la droite de l'écran (choix de Tom).
const TRACE := [
	Vector3(-5, 0, 5), Vector3(-14, 0, 18), Vector3(-30, 0, 28), Vector3(-46, 0, 24),
	Vector3(-60, 0, 36), Vector3(-66, 0, 52), Vector3(-80, 0, 64), Vector3(-98, 0, 60),
	Vector3(-112, 0, 72), Vector3(-118, 0, 90), Vector3(-132, 0, 104), Vector3(-150, 0, 112),
]
## Le ruisseau, qui croise le sentier au niveau du pont.
const RUISSEAU := [
	Vector3(-88, 0, -10), Vector3(-74, 0, 2), Vector3(-62, 0, 15), Vector3(-53, 0, 30),
	Vector3(-48, 0, 48), Vector3(-35, 0, 70), Vector3(-30, 0, 95), Vector3(-18, 0, 120),
]

const RUINE := Vector3(-34, 0, 13)
const AUTEL := Vector3(-90, 0, 72)
const CHARRETTE := Vector3(-122, 0, 99)
## Le centre du hameau de Bruneval (construit à l'étape 9).
const VILLAGE := Vector3(-166, 0, 122)

var courbe_chemin: Curve3D
var courbe_ruisseau: Curve3D
## Le pont : là où le sentier croise le ruisseau, et la direction du sentier à cet endroit.
var PONT := Vector3.ZERO
var direction_pont := Vector3.FORWARD
var _points_chemin: PackedVector3Array
var _points_ruisseau: PackedVector3Array


func _init() -> void:
	courbe_chemin = _courbe_douce(TRACE)
	courbe_ruisseau = _courbe_douce(RUISSEAU)
	_points_chemin = courbe_chemin.get_baked_points()
	_points_ruisseau = courbe_ruisseau.get_baked_points()
	_placer_le_pont()


func _placer_le_pont() -> void:
	var meilleur := 0
	var plus_proche := INF
	for i in _points_chemin.size():
		var d := distance_au_ruisseau(_points_chemin[i])
		if d < plus_proche:
			plus_proche = d
			meilleur = i
	PONT = _points_chemin[meilleur]
	var avant := _points_chemin[max(meilleur - 2, 0)]
	var apres := _points_chemin[min(meilleur + 2, _points_chemin.size() - 1)]
	direction_pont = (apres - avant).normalized()


## Distance (au sol) entre un point et le milieu du sentier.
func distance_au_chemin(p: Vector3) -> float:
	return _distance_a_la_ligne(p, _points_chemin)


## Distance (au sol) entre un point et le milieu du ruisseau.
func distance_au_ruisseau(p: Vector3) -> float:
	return _distance_a_la_ligne(p, _points_ruisseau)


## Une ligne qui passe par tous les points en arrondissant les virages.
func _courbe_douce(points: Array) -> Curve3D:
	var courbe := Curve3D.new()
	courbe.bake_interval = 1.0
	for i in points.size():
		var avant: Vector3 = points[max(i - 1, 0)]
		var apres: Vector3 = points[min(i + 1, points.size() - 1)]
		var poignee := (apres - avant) * 0.25
		courbe.add_point(points[i], -poignee, poignee)
	return courbe


func _distance_a_la_ligne(p: Vector3, points: PackedVector3Array) -> float:
	var q := Vector2(p.x, p.z)
	var meilleure := INF
	for i in points.size() - 1:
		var a := Vector2(points[i].x, points[i].z)
		var b := Vector2(points[i + 1].x, points[i + 1].z)
		var ab := b - a
		var t := clampf((q - a).dot(ab) / max(ab.length_squared(), 0.0001), 0.0, 1.0)
		meilleure = min(meilleure, q.distance_to(a + ab * t))
	return meilleure
