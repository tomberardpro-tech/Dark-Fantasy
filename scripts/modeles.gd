class_name Modeles
## Outil commun pour poser les modèles 3D des packs Quaternius dans le jeu,
## assombris et teintés vers la palette (voir CONTEXTE.md).

const NATURE := "res://assets/nature/"
const OBJETS := "res://assets/objets/"

## Teinte par défaut des objets (bois, métal, pierre) pour qu'ils restent sombres.
const TEINTE_OBJETS := Color(0.62, 0.6, 0.66)

static var _scenes := {}
static var _materiaux := {}


## Crée un modèle à partir de son nom, par exemple Modeles.creer("Barrel").
static func creer(nom: String, dossier := OBJETS, teinte := TEINTE_OBJETS) -> Node3D:
	var chemin := dossier + nom + ".gltf"
	if not _scenes.has(chemin):
		_scenes[chemin] = load(chemin)
	var objet := (_scenes[chemin] as PackedScene).instantiate() as Node3D
	teinter(objet, teinte)
	return objet


## Le matériau (texture) d'un modèle, pour habiller une forme simple avec le même
## bois ou la même pierre que les objets du pack.
static func materiau_de(nom: String, dossier := OBJETS, teinte := TEINTE_OBJETS) -> Material:
	var objet := creer(nom, dossier, teinte)
	var maillage := objet.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mat := maillage.get_surface_override_material(0)
	objet.free()
	return mat


## Remplace les matériaux du modèle par une version assombrie et teintée.
static func teinter(objet: Node, teinte: Color) -> void:
	for maillage in objet.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = maillage.mesh
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i) as StandardMaterial3D
			if mat == null:
				continue
			var cle := [mat, teinte]
			if not _materiaux.has(cle):
				var copie := mat.duplicate() as StandardMaterial3D
				copie.albedo_color = mat.albedo_color * teinte
				copie.roughness = 1.0
				copie.metallic_specular = 0.2
				_materiaux[cle] = copie
			maillage.set_surface_override_material(i, _materiaux[cle])
