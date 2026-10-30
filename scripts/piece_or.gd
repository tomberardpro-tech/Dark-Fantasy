extends Node3D
## Une pièce d'or lâchée par un monstre : elle saute un peu hors du tas d'os, retombe et
## tourne sur elle-même en brillant. Quand le héros passe tout près, elle file vers lui et
## s'ajoute à son or. Au bout d'une minute, elle disparaît.

## Ce que vaut la pièce (en pièces d'or).
@export var valeur := 1

const ATTIRE_A := 1.8
const RAMASSE_A := 0.45
const DUREE_DE_VIE := 60.0

var _vitesse := Vector3.ZERO
var _au_sol := false
var _temps := 0.0
var _attiree := false
var _modele: Node3D


func _ready() -> void:
	_modele = Modeles.creer("Coin", Modeles.OBJETS, Color(1.25, 1.05, 0.6))
	_modele.scale = Vector3.ONE * 1.6
	add_child(_modele)
	# Une petite lueur dorée pour qu'on la voie dans la nuit.
	var lueur := OmniLight3D.new()
	lueur.light_color = Color("f0ad55")
	lueur.light_energy = 0.35
	lueur.omni_range = 1.2
	lueur.position.y = 0.2
	add_child(lueur)
	# Elle jaillit dans une direction au hasard.
	var angle := randf() * TAU
	_vitesse = Vector3(cos(angle), 0.0, sin(angle)) * randf_range(1.0, 2.2) + Vector3.UP * randf_range(3.0, 4.5)


func _process(delta: float) -> void:
	_temps += delta
	if _temps > DUREE_DE_VIE:
		queue_free()
		return
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	if joueur and _temps > 0.5:
		var vers := joueur.global_position + Vector3.UP * 0.8 - global_position
		if _attiree or vers.length() < ATTIRE_A:
			_attiree = true
			global_position += vers.normalized() * minf(vers.length(), (6.0 + _temps * 4.0) * delta)
			if vers.length() < RAMASSE_A:
				joueur.ajouter_pieces(valeur)
				queue_free()
			return
	if not _au_sol:
		_vitesse += Vector3.DOWN * 12.0 * delta
		global_position += _vitesse * delta
		if global_position.y <= 0.12 and _vitesse.y < 0.0:
			global_position.y = 0.12
			_au_sol = true
	# Elle tourne et flotte doucement.
	_modele.rotation.y += delta * 3.0
	if _au_sol:
		_modele.position.y = 0.05 + sin(_temps * 3.0) * 0.04
