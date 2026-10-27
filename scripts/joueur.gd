extends CharacterBody3D
## Personnage temporaire (une capsule encapuchonnée).
## ZQSD ou clic de souris pour marcher, Maj pour courir, Espace pour une roulade.
## Il peut s'asseoir (voir tronc.gd) et se relève dès qu'on bouge.

@export var vitesse_marche := 4.0
@export var vitesse_course := 7.0
@export var vitesse_roulade := 11.0
## Durée d'une roulade, en secondes.
@export var duree_roulade := 0.35
## Le personnage commence-t-il assis sur le tronc ?
@export var assis_au_depart := true

var est_assis := false

var _cible_clic: Variant = null
var _clic_maintenu := false
var _roulade_restante := 0.0
var _direction_roulade := Vector3.ZERO
var _attente_roulade := 0.0

@onready var _visuel: Node3D = $Visuel
@onready var _pivot: Node3D = $Visuel/Pivot


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_clic_maintenu = event.pressed
		if event.pressed:
			_viser_la_souris()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := _direction_clavier()
	if direction.length() > 0.01:
		_cible_clic = null
	elif _clic_maintenu:
		_viser_la_souris()
	if _cible_clic != null:
		var vers: Vector3 = _cible_clic - global_position
		vers.y = 0.0
		if vers.length() < 0.15:
			_cible_clic = null
		else:
			direction = vers.normalized()

	_attente_roulade -= delta
	if Input.is_action_just_pressed("roulade") and _attente_roulade <= 0.0:
		_commencer_roulade(direction)

	if est_assis:
		if direction.length() > 0.01:
			se_relever()
		else:
			return

	if _roulade_restante > 0.0:
		_roulade_restante -= delta
		velocity.x = _direction_roulade.x * vitesse_roulade
		velocity.z = _direction_roulade.z * vitesse_roulade
		var avancement := clampf(1.0 - _roulade_restante / duree_roulade, 0.0, 1.0)
		_pivot.rotation.x = -TAU * avancement
		if _roulade_restante <= 0.0:
			_pivot.rotation.x = 0.0
	else:
		var vitesse := vitesse_course if Input.is_action_pressed("courir") else vitesse_marche
		velocity.x = direction.x * vitesse
		velocity.z = direction.z * vitesse

	var au_sol := Vector3(velocity.x, 0.0, velocity.z)
	if au_sol.length() > 0.1:
		var angle := atan2(-au_sol.x, -au_sol.z)
		_visuel.rotation.y = lerp_angle(_visuel.rotation.y, angle, 1.0 - exp(-12.0 * delta))
	move_and_slide()


## Assoit le personnage à un endroit précis, tourné dans une direction.
func asseoir(point: Vector3, regard: Vector3) -> void:
	est_assis = true
	_cible_clic = null
	velocity = Vector3.ZERO
	global_position = point
	_visuel.rotation.y = atan2(-regard.x, -regard.z)
	# Plus bas, plus court et un peu en arrière : il est posé sur le tronc.
	_pivot.position = Vector3(0.0, 1.1, 0.45)
	_pivot.scale = Vector3(1.0, 0.55, 1.0)


func se_relever() -> void:
	est_assis = false
	_pivot.position = Vector3(0.0, 0.9, 0.0)
	_pivot.scale = Vector3.ONE


## ZQSD converti en direction au sol, selon l'angle de la caméra (haut de l'écran = Z).
func _direction_clavier() -> Vector3:
	var entree := Input.get_vector("gauche", "droite", "reculer", "avancer")
	if entree.length() < 0.01:
		return Vector3.ZERO
	var camera := get_viewport().get_camera_3d()
	var avant := Vector3(0, 0, -1)
	var droite := Vector3(1, 0, 0)
	if camera:
		avant = -camera.global_basis.z
		avant.y = 0.0
		avant = avant.normalized()
		droite = camera.global_basis.x
		droite.y = 0.0
		droite = droite.normalized()
	return (droite * entree.x + avant * entree.y).limit_length(1.0)


func _commencer_roulade(direction: Vector3) -> void:
	if est_assis:
		se_relever()
	if direction.length() < 0.01:
		direction = -_visuel.global_basis.z
	_direction_roulade = Vector3(direction.x, 0.0, direction.z).normalized()
	_roulade_restante = duree_roulade
	_attente_roulade = duree_roulade + 0.25


## Le point du sol sous la souris devient la destination.
func _viser_la_souris() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var souris := get_viewport().get_mouse_position()
	var point: Variant = Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(souris), camera.project_ray_normal(souris))
	if point != null:
		_cible_clic = point
