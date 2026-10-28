extends MeshInstance3D
## Une traînée lumineuse qui suit la lame pendant un coup d'épée, puis s'efface en douceur.
## À chaque image, on lui donne la base et la pointe de la lame ; elle garde les dernières
## positions et dessine un ruban entre elles, de plus en plus transparent vers l'arrière.

## Combien de temps une position de la lame reste visible (en secondes).
@export var duree := 0.16
@export var couleur := Color(0.78, 0.82, 0.95, 0.55)

var _points: Array = []
var _maillage := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _maillage
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	material_override = mat


## À appeler à chaque image. « actif » : la lame frappe en ce moment.
func suivre(base: Vector3, pointe: Vector3, actif: bool, delta: float) -> void:
	for p in _points:
		p["age"] += delta
	_points = _points.filter(func(p): return p["age"] < duree)
	if actif:
		_points.push_front({"base": base, "pointe": pointe, "age": 0.0})
	_dessiner()


func _dessiner() -> void:
	_maillage.clear_surfaces()
	if _points.size() < 2:
		return
	_maillage.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for p in _points:
		var force: float = 1.0 - p["age"] / duree
		var c := couleur
		c.a *= force * force
		_maillage.surface_set_color(Color(c.r, c.g, c.b, 0.0))
		_maillage.surface_add_vertex(p["base"])
		_maillage.surface_set_color(c)
		_maillage.surface_add_vertex(p["pointe"])
	_maillage.surface_end()
