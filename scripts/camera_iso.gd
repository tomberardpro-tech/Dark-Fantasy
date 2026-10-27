extends Camera3D
## Caméra isométrique fixe (façon Diablo) : même angle que sur la maquette.
## Elle suit doucement le personnage sans jamais tourner.

## Le personnage (ou l'objet) que la caméra suit.
@export var a_suivre: Node3D
## D'où regarde la caméra par rapport à la cible (angle de la maquette).
@export var direction := Vector3(-19, 20, -18)
## Distance entre la caméra et la cible.
@export var distance := 30.0
## Taille de la zone visible : plus c'est grand, plus on voit loin (on « dézoome »).
@export var zoom := 18.0
## Rapidité avec laquelle la caméra rattrape le personnage.
@export var douceur := 6.0

var _cible := Vector3.ZERO


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = zoom
	if a_suivre:
		_cible = a_suivre.global_position
	_placer()


func _process(delta: float) -> void:
	if a_suivre:
		_cible = _cible.lerp(a_suivre.global_position, 1.0 - exp(-douceur * delta))
	_placer()


func _placer() -> void:
	position = _cible + direction.normalized() * distance
	look_at(_cible)
