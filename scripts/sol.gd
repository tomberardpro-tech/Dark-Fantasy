extends MeshInstance3D
## Le sol, fait comme sur la maquette : un quadrillage plat dont chaque point reçoit une
## couleur. Trois verts éteints forment des taches irrégulières, et la terre brune
## apparaît autour du feu.

## Taille du sol (en mètres, de chaque côté).
@export var taille := 120.0
## Écart entre deux points du quadrillage (plus petit = taches plus fines).
@export var pas := 1.0

const VERTS := [Color("26332f"), Color("2e3d3a"), Color("3a4a43")]
const TERRE := Color("463830")


func _ready() -> void:
	var outil := SurfaceTool.new()
	outil.begin(Mesh.PRIMITIVE_TRIANGLES)
	outil.set_normal(Vector3.UP)
	var n := int(taille / pas)
	var debut := -taille / 2.0
	for i in n + 1:
		for j in n + 1:
			var x := debut + i * pas
			var z := debut + j * pas
			outil.set_color(_couleur(x, z))
			outil.add_vertex(Vector3(x, 0.0, z))
	for i in n:
		for j in n:
			var a := i * (n + 1) + j
			var b := a + n + 1
			outil.add_index(a)
			outil.add_index(b)
			outil.add_index(a + 1)
			outil.add_index(a + 1)
			outil.add_index(b)
			outil.add_index(b + 1)
	mesh = outil.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	material_override = mat


func _couleur(x: float, z: float) -> Color:
	# Même formule que la maquette : des taches de trois verts.
	var indice := int(floor((sin(x * 1.7) * cos(z * 1.3) + 1.0) * 1.49))
	var c: Color = VERTS[clampi(indice, 0, VERTS.size() - 1)]
	# La terre autour du feu, qui se fond dans l'herbe.
	var r := Vector2(x, z).length()
	if r < 5.5:
		c = c.lerp(TERRE, 1.0 - smoothstep(3.5, 5.5, r) * 0.7)
	return c
