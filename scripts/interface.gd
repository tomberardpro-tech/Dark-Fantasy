extends CanvasLayer
## Messages affichés en bas de l'écran, par exemple « E : s'asseoir »,
## notifications en haut (« Partie sauvegardée ») et la barre de vie en bas à gauche.

var _message: Label
var _annonce: Label
var _fondu: Tween
var _barre_vie: ProgressBar
## La lettre affichée en grand (créée la première fois qu'on en lit une).
var _lettre: Control
var _ouverte_a := -1
## La bulle de dialogue, les répliques en cours et le personnage qui parle.
const LETTRES_PAR_SECONDE := 45.0
var _bulle: PanelContainer
var _repliques: Array[String] = []
var _numero := 0
var _interlocuteur: Node
var _lettres := 0.0
var _bulle_ouverte_a := -1


func _ready() -> void:
	# L'interface continue de marcher quand le jeu est en pause (pendant une lecture).
	process_mode = Node.PROCESS_MODE_ALWAYS
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


## Une conversation : une bulle en bas de l'écran avec le nom et la réplique, qui s'écrit
## lettre par lettre. E : affiche tout de suite la réplique entière, puis passe à la
## suivante ; après la dernière, la bulle se ferme et le personnage reprend son activité.
func parler(nom: String, repliques: Array[String], interlocuteur: Node) -> void:
	if _bulle == null:
		_creer_bulle()
	_repliques = repliques
	_numero = 0
	_interlocuteur = interlocuteur
	_bulle.get_node("%Nom").text = nom
	_montrer_replique()
	_bulle.show()
	_bulle.modulate.a = 0.0
	create_tween().tween_property(_bulle, "modulate:a", 1.0, 0.2)
	_bulle_ouverte_a = Engine.get_process_frames()
	_message.hide()


func dialogue_ouvert() -> bool:
	return _bulle != null and _bulle.visible


func _montrer_replique() -> void:
	var texte := _bulle.get_node("%Texte") as Label
	texte.text = _repliques[_numero]
	texte.visible_ratio = 0.0
	_lettres = 0.0


func _avancer_dialogue(delta: float) -> void:
	var texte := _bulle.get_node("%Texte") as Label
	var total := texte.get_total_character_count()
	if texte.visible_characters >= 0 and texte.visible_characters < total:
		_lettres += delta * LETTRES_PAR_SECONDE
		texte.visible_characters = mini(int(_lettres), total)
		if texte.visible_characters >= total:
			texte.visible_characters = -1
	if Engine.get_process_frames() == _bulle_ouverte_a or not Input.is_action_just_pressed("interagir"):
		return
	if texte.visible_characters != -1:
		texte.visible_characters = -1
	elif _numero + 1 < _repliques.size():
		_numero += 1
		_montrer_replique()
	else:
		_bulle.hide()
		if is_instance_valid(_interlocuteur) and _interlocuteur.has_method("fin_de_dialogue"):
			_interlocuteur.fin_de_dialogue()


func _creer_bulle() -> void:
	_bulle = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.035, 0.07, 0.86)
	style.border_color = Color("5a4630")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(18)
	_bulle.add_theme_stylebox_override("panel", style)
	add_child(_bulle)
	_bulle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_bulle.offset_left = -330.0
	_bulle.offset_right = 330.0
	_bulle.offset_top = -170.0
	_bulle.offset_bottom = -40.0
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 8)
	_bulle.add_child(colonne)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	for partie in [["Nom", 18, Color("d8b46a")], ["Texte", 17, Color("d7dbe6")], ["Suite", 12, Color(0.75, 0.78, 0.85, 0.5)]]:
		var etiquette := Label.new()
		etiquette.name = partie[0]
		etiquette.unique_name_in_owner = true
		etiquette.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		etiquette.custom_minimum_size.x = 620
		etiquette.add_theme_font_size_override("font_size", partie[1])
		etiquette.add_theme_color_override("font_color", partie[2])
		if partie[0] == "Texte":
			etiquette.add_theme_font_override("font", serif)
			etiquette.custom_minimum_size.y = 52
		if partie[0] == "Suite":
			etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			etiquette.text = "E : continuer"
		colonne.add_child(etiquette)
		etiquette.owner = _bulle


## On découvre un lieu : son nom apparaît en grand au milieu de l'écran, entre deux
## traits, puis s'efface lentement.
func annoncer_lieu(nom: String) -> void:
	var titre := Label.new()
	titre.text = nom
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 46)
	titre.add_theme_color_override("font_color", Color("d8cdb4"))
	titre.add_theme_color_override("font_outline_color", Color("07091a"))
	titre.add_theme_constant_override("outline_size", 10)
	add_child(titre)
	titre.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	titre.offset_left = -300.0
	titre.offset_right = 300.0
	titre.offset_top = -170.0
	titre.offset_bottom = -110.0
	titre.modulate.a = 0.0
	var anim := create_tween()
	anim.tween_property(titre, "modulate:a", 1.0, 1.4).set_ease(Tween.EASE_OUT)
	anim.tween_interval(2.6)
	anim.tween_property(titre, "modulate:a", 0.0, 2.0)
	anim.tween_callback(titre.queue_free)


## Affiche une lettre en grand, sur une feuille de parchemin, le jeu en pause.
## E ou Échap pour la refermer.
func lire_lettre(titre: String, texte: String, signature: String) -> void:
	if _lettre == null:
		_creer_lettre()
	_lettre.get_node("%Titre").text = titre
	_lettre.get_node("%Texte").text = texte
	_lettre.get_node("%Signature").text = signature
	_lettre.show()
	_lettre.modulate.a = 0.0
	create_tween().tween_property(_lettre, "modulate:a", 1.0, 0.35)
	_ouverte_a = Engine.get_process_frames()
	_message.hide()
	get_tree().paused = true


func lettre_ouverte() -> bool:
	return _lettre != null and _lettre.visible


func _process(delta: float) -> void:
	if dialogue_ouvert():
		_avancer_dialogue(delta)
		return
	if not lettre_ouverte() or Engine.get_process_frames() == _ouverte_a:
		return
	if Input.is_action_just_pressed("interagir") or Input.is_action_just_pressed("ui_cancel"):
		_lettre.hide()
		Sons.jouer("papier_ferme")
		get_tree().set_deferred("paused", false)


func _creer_lettre() -> void:
	_lettre = Control.new()
	_lettre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lettre.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_lettre)
	var voile := ColorRect.new()
	voile.color = Color(0.0, 0.0, 0.02, 0.6)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lettre.add_child(voile)
	# La feuille de parchemin, au centre.
	var feuille := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("c9b791")
	style.border_color = Color("5a4630")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 18
	style.set_content_margin_all(34)
	feuille.add_theme_stylebox_override("panel", style)
	feuille.custom_minimum_size = Vector2(560, 0)
	_lettre.add_child(feuille)
	feuille.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	feuille.grow_horizontal = Control.GROW_DIRECTION_BOTH
	feuille.grow_vertical = Control.GROW_DIRECTION_BOTH
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	feuille.add_child(colonne)
	var encre := Color("2b2018")
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	serif.font_italic = true
	for partie in [["Titre", 15, HORIZONTAL_ALIGNMENT_CENTER], ["Texte", 17, HORIZONTAL_ALIGNMENT_LEFT],
			["Signature", 17, HORIZONTAL_ALIGNMENT_RIGHT], ["Fermer", 12, HORIZONTAL_ALIGNMENT_CENTER]]:
		var texte := Label.new()
		texte.name = partie[0]
		texte.unique_name_in_owner = true
		texte.horizontal_alignment = partie[2]
		texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texte.custom_minimum_size.x = 492
		texte.add_theme_font_size_override("font_size", partie[1])
		texte.add_theme_color_override("font_color", encre)
		if partie[0] == "Texte" or partie[0] == "Signature":
			texte.add_theme_font_override("font", serif)
		colonne.add_child(texte)
		texte.owner = _lettre
	var fermer := _lettre.get_node("%Fermer") as Label
	fermer.text = "E : refermer la lettre"
	fermer.add_theme_color_override("font_color", Color(encre, 0.55))


func afficher(texte: String) -> void:
	_message.text = texte
	_message.show()


func cacher() -> void:
	_message.hide()
