extends Node3D
## Un objet d'information : une lettre posée quelque part. Un faisceau de lumière dorée
## monte au-dessus tant qu'on ne l'a pas lue. Touche E à côté : elle s'affiche en grand
## à l'écran (voir interface.gd, lire_lettre). Réutilisable pour toutes les notes du jeu.

@export var titre := ""
@export_multiline var texte := ""
@export_multiline var signature := ""
## Distance à laquelle « E : lire la lettre » apparaît.
@export var distance_interaction := 1.7

var lue := false
var _faisceau: MeshInstance3D
var _lueur: OmniLight3D
var _temps := 0.0


func _ready() -> void:
	add_to_group("interactif")
	_creer_feuille()
	_creer_faisceau()


func _process(delta: float) -> void:
	_temps += delta
	# Le faisceau respire doucement.
	if _lueur and not lue:
		_lueur.light_energy = 0.8 + sin(_temps * 1.6) * 0.2


## Une feuille de papier jauni, avec des lignes d'écriture.
func _creer_feuille() -> void:
	var feuille := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2(0.21, 0.29)
	feuille.mesh = plan
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/papier.gdshader")
	feuille.material_override = mat
	add_child(feuille)


## Un fin faisceau de lumière dorée qui monte de la lettre, et une petite lueur.
func _creer_faisceau() -> void:
	_faisceau = MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.22
	tube.bottom_radius = 0.12
	tube.height = 2.6
	tube.radial_segments = 16
	tube.cap_top = false
	tube.cap_bottom = false
	_faisceau.mesh = tube
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/faisceau.gdshader")
	mat.set_shader_parameter("force", 0.55)
	_faisceau.material_override = mat
	_faisceau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_faisceau.position.y = 1.3
	add_child(_faisceau)
	_lueur = OmniLight3D.new()
	_lueur.light_color = Color("f2c46b")
	_lueur.light_energy = 0.8
	_lueur.omni_range = 2.2
	_lueur.position.y = 0.25
	add_child(_lueur)


func distance_pour_interagir(joueur: Node3D) -> float:
	var d := Vector2(joueur.global_position.x - global_position.x, joueur.global_position.z - global_position.z).length()
	return d if d < distance_interaction else INF


func texte_interaction(_joueur: Node3D) -> String:
	return "E : lire la lettre"


func interagir(_joueur: Node3D) -> void:
	var interface := get_tree().get_first_node_in_group("interface")
	if interface:
		interface.lire_lettre(titre, texte, signature)
	if not lue:
		lue = true
		# Une fois lue, le faisceau s'éteint doucement (la lettre reste lisible).
		var anim := create_tween().set_parallel()
		anim.tween_property(_faisceau.material_override, "shader_parameter/force", 0.0, 1.5)
		anim.tween_property(_lueur, "light_energy", 0.0, 1.5)
