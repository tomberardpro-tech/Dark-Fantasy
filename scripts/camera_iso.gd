extends Camera3D
## Caméra isométrique fixe (façon Diablo) : elle regarde toujours la cible sous le même angle.

## Le point que la caméra regarde (plus tard : le personnage).
@export var cible := Vector3.ZERO
## Distance entre la caméra et la cible.
@export var distance := 30.0
## Taille de la zone visible : plus c'est grand, plus on voit loin (on « dézoome »).
@export var zoom := 22.0


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = zoom
	position = cible + Vector3(1, 1, 1).normalized() * distance
	look_at(cible)
