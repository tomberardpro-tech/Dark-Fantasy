extends Node
## Le plan de la zone de départ : le tracé du chemin de la clairière jusqu'à Bruneval,
## le ruisseau, et l'emplacement des lieux à découvrir en route.
## Les autres scripts lui demandent par exemple « suis-je loin du chemin ? »
## (pour ne pas planter d'arbre au milieu).

## Les points de passage du sentier, de la clairière jusqu'à l'entrée de Bruneval.
## Avec la caméra du jeu, le chemin part vers la droite de l'écran (choix de Tom).
## Il commence tout près du feu, pour sortir de la clairière en douceur.
const TRACE := [
	Vector3(-2, 0, 2.5), Vector3(-7, 0, 9), Vector3(-14, 0, 18), Vector3(-30, 0, 28), Vector3(-46, 0, 24),
	Vector3(-60, 0, 36), Vector3(-66, 0, 52), Vector3(-80, 0, 64), Vector3(-98, 0, 60),
	Vector3(-112, 0, 72), Vector3(-118, 0, 90), Vector3(-127, 0, 99),
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
const VILLAGE := Vector3(-137, 0, 109)

var courbe_chemin: Curve3D
var courbe_ruisseau: Curve3D
## Le pont : là où le sentier croise le ruisseau, et la direction du sentier à cet endroit.
var PONT := Vector3.ZERO
var direction_pont := Vector3.FORWARD
var _points_chemin: PackedVector3Array
var _points_ruisseau: PackedVector3Array


## Le sentier serpente de part et d'autre du tracé (en mètres), comme un vrai chemin
## qui contourne les arbres ; mais il reste droit au départ, au pont, près des lieux et
## à l'arrivée.
const SERPENTE := 1.8
## Demi-largeur moyenne du sentier (en mètres) ; elle varie le long du chemin.
const DEMI_LARGEUR := 0.9


func _init() -> void:
	courbe_ruisseau = _courbe_douce(RUISSEAU)
	_points_ruisseau = courbe_ruisseau.get_baked_points()
	courbe_chemin = _serpenter(_courbe_douce(TRACE))
	_points_chemin = courbe_chemin.get_baked_points()
	_placer_le_pont()


## La demi-largeur du sentier à cette distance du départ : il s'élargit et se resserre,
## usé par les passages (entre 0,65 et 1,15 m).
func demi_largeur(parcouru: float) -> float:
	return DEMI_LARGEUR * (1.0 + sin(parcouru * 0.21 + 1.0) * 0.16 + sin(parcouru * 0.57) * 0.1)


## Décale le tracé de côté, en douces ondulations (deux vagues de longueurs différentes,
## pour que ce ne soit pas régulier).
func _serpenter(base: Curve3D) -> Curve3D:
	var longueur := base.get_baked_length()
	var points := []
	var s := 0.0
	while s < longueur:
		points.append(_point_serpente(base, s, longueur))
		s += 3.0
	points.append(_point_serpente(base, longueur, longueur))
	return _courbe_douce(points)


func _point_serpente(base: Curve3D, s: float, longueur: float) -> Vector3:
	var p := base.sample_baked(s)
	var tangente := (base.sample_baked(min(s + 1.0, longueur)) - base.sample_baked(max(s - 1.0, 0.0))).normalized()
	var cote := Vector3(-tangente.z, 0.0, tangente.x)
	var force := smoothstep(8.0, 20.0, s) * smoothstep(0.0, 12.0, longueur - s)
	force *= smoothstep(8.0, 18.0, distance_au_ruisseau(p))
	for lieu in [RUINE, AUTEL, CHARRETTE]:
		force *= smoothstep(6.0, 12.0, p.distance_to(lieu))
	var vague := sin(s * TAU / 31.0 + 0.7) * 0.65 + sin(s * TAU / 13.0 + 2.1) * 0.35
	return p + cote * vague * SERPENTE * force


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
