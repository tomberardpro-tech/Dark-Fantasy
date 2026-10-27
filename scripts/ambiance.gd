extends Node3D
## L'ambiance de la forêt de nuit, toujours autour du personnage :
## des lucioles qui flottent doucement et des feuilles emportées par le vent.
## (La brume au ras du sol est réglée dans l'environnement de la scène.)

@export var nombre_lucioles := 45
@export var nombre_feuilles := 35
## Taille de la zone autour du personnage où apparaissent lucioles et feuilles.
@export var zone := 32.0

var _feuilles: CPUParticles3D


func _ready() -> void:
	add_child(_creer_lucioles())
	_feuilles = _creer_feuilles()
	add_child(_feuilles)


func _process(_delta: float) -> void:
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	if joueur:
		global_position = joueur.global_position
	# Les feuilles suivent la force du vent du moment (les rafales).
	var vent := Vent.souffle(Time.get_ticks_msec() / 1000.0, global_position)
	_feuilles.direction = vent.normalized() + Vector3(0, 0.15, 0)
	_feuilles.initial_velocity_min = 0.8 + vent.length() * 2.0
	_feuilles.initial_velocity_max = 1.5 + vent.length() * 3.5


func _creer_lucioles() -> CPUParticles3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var forme := QuadMesh.new()
	forme.size = Vector2(0.07, 0.07)
	forme.material = mat
	var lucioles := CPUParticles3D.new()
	lucioles.mesh = forme
	lucioles.amount = nombre_lucioles
	lucioles.lifetime = 7.0
	lucioles.local_coords = false
	lucioles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	lucioles.emission_box_extents = Vector3(zone / 2.0, 1.0, zone / 2.0)
	lucioles.position.y = 1.2
	lucioles.gravity = Vector3.ZERO
	lucioles.direction = Vector3.UP
	lucioles.spread = 180.0
	lucioles.initial_velocity_min = 0.1
	lucioles.initial_velocity_max = 0.35
	# Elles s'allument, brillent un moment, puis s'éteignent doucement.
	var couleurs := Gradient.new()
	couleurs.set_color(0, Color(1.0, 0.88, 0.63, 0.0))
	couleurs.add_point(0.3, Color(1.0, 0.88, 0.63, 0.9))
	couleurs.add_point(0.7, Color(0.94, 0.68, 0.33, 0.7))
	couleurs.set_color(couleurs.get_point_count() - 1, Color(0.94, 0.68, 0.33, 0.0))
	lucioles.color_ramp = couleurs
	return lucioles


func _creer_feuilles() -> CPUParticles3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	var forme := QuadMesh.new()
	forme.size = Vector2(0.14, 0.09)
	forme.material = mat
	var feuilles := CPUParticles3D.new()
	feuilles.mesh = forme
	feuilles.amount = nombre_feuilles
	feuilles.lifetime = 6.0
	feuilles.local_coords = false
	feuilles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	feuilles.emission_box_extents = Vector3(zone / 2.0, 2.0, zone / 2.0)
	feuilles.position.y = 4.0
	feuilles.gravity = Vector3(0, -0.4, 0)
	feuilles.spread = 25.0
	feuilles.particle_flag_align_y = false
	feuilles.angular_velocity_min = -180.0
	feuilles.angular_velocity_max = 180.0
	feuilles.angle_min = 0.0
	feuilles.angle_max = 360.0
	# Feuilles mortes : bruns et verts éteints, comme le reste de la palette.
	var teintes := Gradient.new()
	teintes.set_color(0, Color("463830"))
	teintes.add_point(0.5, Color("3a4a43"))
	teintes.set_color(teintes.get_point_count() - 1, Color("64544a"))
	feuilles.color_initial_ramp = teintes
	return feuilles
