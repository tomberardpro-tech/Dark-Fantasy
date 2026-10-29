extends CanvasLayer
## Messages affichés en bas de l'écran, par exemple « E : s'asseoir »,
## notifications en haut (« Partie sauvegardée ») et la barre de vie en bas à gauche.

var _message: Label
var _annonce: Label
var _fondu: Tween
var _barre_vie: ProgressBar


func _ready() -> void:
	_creer_barre_de_vie()

	# L'indicateur de destination en haut de l'écran (voir objectif.gd).
	var objectif := Control.new()
	objectif.set_script(load("res://scripts/objectif.gd"))
	add_child(objectif)
	objectif.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	objectif.offset_bottom = 80.0

	_annonce = Label.new()
	_annonce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_annonce.add_theme_font_size_override("font_size", 26)
	_annonce.add_theme_color_override("font_color", Color("f0ad55"))
	_annonce.add_theme_color_override("font_outline_color", Color("07091a"))
	_annonce.add_theme_constant_override("outline_size", 8)
	add_child(_annonce)
	_annonce.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_annonce.offset_left = -250.0
	_annonce.offset_right = 250.0
	_annonce.offset_top = 86.0
	_annonce.offset_bottom = 126.0
	_annonce.hide()

	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 22)
	_message.add_theme_color_override("font_color", Color("c3cde6"))
	_message.add_theme_color_override("font_outline_color", Color("07091a"))
	_message.add_theme_constant_override("outline_size", 6)
	add_child(_message)
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_message.offset_left = -200.0
	_message.offset_right = 200.0
	_message.offset_top = -70.0
	_message.offset_bottom = -40.0
	_message.hide()


## Une petite barre de vie fine et arrondie, discrète, en bas à gauche.
func _creer_barre_de_vie() -> void:
	_barre_vie = ProgressBar.new()
	_barre_vie.show_percentage = false
	_barre_vie.max_value = 100.0
	_barre_vie.value = 100.0
	_barre_vie.custom_minimum_size = Vector2(180, 5)
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0.027, 0.035, 0.102, 0.75)
	fond.border_color = Color("3f4c7e")
	fond.set_border_width_all(1)
	fond.set_corner_radius_all(3)
	var plein := StyleBoxFlat.new()
	plein.bg_color = Color("4f8a3c")
	plein.set_corner_radius_all(3)
	_barre_vie.add_theme_stylebox_override("background", fond)
	_barre_vie.add_theme_stylebox_override("fill", plein)
	add_child(_barre_vie)
	_barre_vie.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_barre_vie.offset_left = 24.0
	_barre_vie.offset_right = 204.0
	_barre_vie.offset_top = -32.0
	_barre_vie.offset_bottom = -27.0


## Met à jour la barre de vie (vie actuelle et maximum).
func vie(actuelle: float, maximum: float) -> void:
	_barre_vie.max_value = maximum
	_barre_vie.value = actuelle


## Un message qui apparaît en haut de l'écran puis s'efface doucement
## (par exemple « Partie sauvegardée »).
func notifier(texte: String) -> void:
	_annonce.text = texte
	_annonce.modulate.a = 1.0
	_annonce.show()
	if _fondu:
		_fondu.kill()
	_fondu = create_tween()
	_fondu.tween_interval(1.5)
	_fondu.tween_property(_annonce, "modulate:a", 0.0, 1.0)
	_fondu.tween_callback(_annonce.hide)


func afficher(texte: String) -> void:
	_message.text = texte
	_message.show()


func cacher() -> void:
	_message.hide()
