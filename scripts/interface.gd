extends CanvasLayer
## Messages affichés en bas de l'écran, par exemple « E : s'asseoir ».

var _message: Label


func _ready() -> void:
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


func afficher(texte: String) -> void:
	_message.text = texte
	_message.show()


func cacher() -> void:
	_message.hide()
