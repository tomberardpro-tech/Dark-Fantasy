extends Node
## Le plan de la zone de départ : le tracé du chemin de la clairière jusqu'à Bruneval,
## le ruisseau, et l'emplacement des lieux à découvrir en route.
## Les autres scripts lui demandent par exemple « suis-je loin du chemin ? »
## (pour ne pas planter d'arbre au milieu).

## Les points de passage du sentier, de la clairière jusqu'à l'entrée de Bruneval
## (environ 125 m). Avec la caméra du jeu, le chemin monte presque tout droit vers le
## haut de l'écran (choix de Tom, d'après la maquette) : il part juste derrière le coffre.
## Repère : le haut de l'écran est la direction (0,73 ; 0 ; 0,69) du monde, la droite
## de l'écran (-0,69 ; 0 ; 0,73).
const TRACE := [
	Vector3(3.99, 0, 3.78), Vector3(7.99, 0, 7.57), Vector3(13.07, 0, 12.38), Vector3(25.98, 0, 19.11), Vector3(30.61, 0, 33.13),
	Vector3(37.98, 0, 44.25), Vector3(47.99, 0, 48.22), Vector3(59.46, 0, 53.57), Vector3(65.42, 0, 64.73),
	Vector3(78.29, 0, 70.04), Vector3(85.67, 0, 81.16), Vector3(92.93, 0, 88.04),
	# Dans le hameau : le chemin va tout droit jusqu'à la place.
	Vector3(99.1, 0, 93.88), Vector3(104.18, 0, 98.7),
]
## Le ruisseau, qui traverse l'écran de gauche à droite et croise le sentier au pont.
const RUISSEAU := [
	Vector3(88.04, 0, -40.58), Vector3(80.63, 0, -26.94), Vector3(68.7, 0, 3.1), Vector3(50.25, 0, 26.94),
	Vector3(37.98, 0, 44.25), Vector3(25.11, 0, 65.11), Vector3(0.84, 0, 83.45), Vector3(-10.54, 0, 107.1),
	Vector3(-28.66, 0, 117.5),
]

## La cabane, à gauche du chemin avant le pont ; sa porte regarde le chemin.
const RUINE := Vector3(30.03, 0, 11.92)
const ROTATION_RUINE := -0.51
## L'autel, à droite du chemin ; la charrette, à gauche juste avant le village.
const AUTEL := Vector3(58.54, 0, 71.99)
const CHARRETTE := Vector3(88.96, 0, 71.88)
const ROTATION_CHARRETTE := 1.6
## La petite cabane de l'écrivain, à droite du chemin juste avant le village ; son fond
## est vers le haut de l'écran et elle est ouverte vers la caméra.
const ABRI := Vector3(73.6, 0, 79.36)
const ROTATION_ABRI := -2.33
## L'entrée de Bruneval (deux torches), et le centre de sa place (le feu).
const ENTREE := Vector3(92.93, 0, 88.04)
const VILLAGE := Vector3(107.81, 0, 102.14)
## Le hameau est dessiné « comme à l'écran » (voir la maquette) : x vers la droite de
## l'écran, y vers le haut, en mètres, à partir de ce point.
const ORIGINE_BRUNEVAL := Vector3(107.81, 0, 102.14)
## La clairière de Bruneval, un ovale (en mètres, comme à l'écran), resserrée autour des
## petites maisons à la demande de Tom.
const DEMI_LARGEUR_BRUNEVAL := 19.0
const DEMI_HAUTEUR_BRUNEVAL := 15.5
const CENTRE_Y_BRUNEVAL := 0.8
const DROITE_ECRAN := Vector3(-0.6878, 0, 0.726)
const HAUT_ECRAN := Vector3(0.726, 0, 0.6878)

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
const SERPENTE := 1.0
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


## Un point du hameau, donné comme sur la maquette (x vers la droite de l'écran, y vers le
## haut, en mètres depuis le centre du hameau).
func bruneval(x: float, y: float) -> Vector3:
	return ORIGINE_BRUNEVAL + DROITE_ECRAN * x + HAUT_ECRAN * y


## Le bord de la clairière de Bruneval : un ovale (comme sur la maquette choisie par Tom),
## à l'angle « t », éventuellement repoussé de « marge » mètres.
func bord_bruneval(t: float, marge := 0.0) -> Vector3:
	return bruneval((DEMI_LARGEUR_BRUNEVAL + marge) * sin(t), CENTRE_Y_BRUNEVAL - (DEMI_HAUTEUR_BRUNEVAL + marge) * cos(t))


## Vrai si ce point est dans la clairière de Bruneval (avec une marge en mètres).
func dans_bruneval(p: Vector3, marge := 0.0) -> bool:
	var local := p - ORIGINE_BRUNEVAL
	var x := local.dot(DROITE_ECRAN)
	var y := local.dot(HAUT_ECRAN) - CENTRE_Y_BRUNEVAL
	return Vector2(x / (DEMI_LARGEUR_BRUNEVAL + marge), y / (DEMI_HAUTEUR_BRUNEVAL + marge)).length() < 1.0
