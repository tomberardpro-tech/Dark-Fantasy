extends Camera3D
## Caméra fixe vue de haut (façon Diablo) : même angle que sur la maquette.
## Elle suit doucement le personnage sans jamais tourner.
## En perspective, ce qui est proche paraît plus grand : la scène a de la profondeur.

## Le personnage (ou l'objet) que la caméra suit.
@export var a_suivre: Node3D
## D'où regarde la caméra par rapport à la cible (angle de la maquette).
@export var direction := Vector3(-19, 20, -18)
## Distance entre la caméra et la cible.
@export var distance := 26.0
## Limites du zoom à la molette (distance la plus proche et la plus lointaine).
@export var distance_min := 14.0
@export var distance_max := 45.0
## Vraie perspective (profondeur) ou vue « plate » sans perspective.
@export var perspective := true
## Ouverture de l'objectif en perspective : petit = effet téléobjectif, grand = grand-angle.
@export_range(10.0, 90.0) var champ_de_vision := 35.0
## Taille de la zone visible en vue plate : plus c'est grand, plus on voit loin.
@export var zoom := 18.0
## Rapidité avec laquelle la caméra rattrape le personnage.
@export var douceur := 6.0

var _cible := Vector3.ZERO


func _ready() -> void:
	if perspective:
		projection = PROJECTION_PERSPECTIVE
		fov = champ_de_vision
	else:
		projection = PROJECTION_ORTHOGONAL
		size = zoom
	if a_suivre:
		_cible = a_suivre.global_position
	_placer()


func _process(delta: float) -> void:
	if a_suivre:
		# Position « adoucie » entre deux pas de physique : la caméra suit le personnage
		# sans à-coups, donc sans effet de flou quand il court.
		var position_lisse := a_suivre.get_global_transform_interpolated().origin
		_cible = _cible.lerp(position_lisse, 1.0 - exp(-douceur * delta))
	_placer()


## Rapproche (pas négatif) ou éloigne (pas positif) la caméra, dans les limites.
func zoomer(pas: float) -> void:
	distance = clampf(distance + pas, distance_min, distance_max)


func _placer() -> void:
	position = _cible + direction.normalized() * distance
	look_at(_cible)
