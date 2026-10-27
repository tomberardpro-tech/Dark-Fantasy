extends CanvasLayer
## Messages affichés en bas de l'écran, par exemple « E : s'asseoir »,
## et notifications en haut, par exemple « Partie sauvegardée ».

var _message: Label
var _annonce: Label
var _fondu: Tween


func _ready() -> void:
	var boussole := Control.new()
	boussole.set_script(load("res://scripts/boussole.gd"))
	add_child(boussole)

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
	_annonce.offset_top = 84.0
	_annonce.offset_bottom = 124.0
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
