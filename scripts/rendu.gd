extends SubViewportContainer
## Effet « 3D pixel » : le monde est calculé en plus petit, puis agrandi sans lissage
## (gros pixels nets), et la palette commune est appliquée par-dessus.
## Pour comparer en jouant : F1 = palette oui/non, F2 = taille des pixels (1 à 4).
## La molette de la souris rapproche ou éloigne la caméra.

## Taille d'un pixel du jeu, en pixels de l'écran (1 = pas d'effet pixel).
@export_range(1, 8) var taille_pixels := 2


func _ready() -> void:
	# Sur un Mac à écran « Retina », il y a deux fois plus de pixels : sans ça, les textes
	# et les fenêtres de l'interface y paraissent deux fois plus petits. On agrandit donc
	# tout, d'un nombre entier seulement (2), et seulement sur Mac : sur PC, un agrandissement
	# à virgule (écran réglé à 125 %…) faisait changer la taille de l'image à chaque instant
	# et tout l'écran clignotait.
	if OS.get_name() == "macOS":
		var densite := roundf(DisplayServer.screen_get_scale())
		if densite > 1.0:
			get_window().content_scale_factor = densite
	stretch = true
	stretch_shrink = taille_pixels
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _input(event: InputEvent) -> void:
	# Molette de la souris : zoomer ou dézoomer la caméra.
	if event is InputEventMouseButton and event.pressed:
		var camera: Camera3D = ($Monde as SubViewport).get_camera_3d()
		if camera and camera.has_method("zoomer"):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.zoomer(-2.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.zoomer(2.0)
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_F1:
		var mat := material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("palette_active", not mat.get_shader_parameter("palette_active"))
	elif event.physical_keycode == KEY_F2:
		taille_pixels = taille_pixels % 4 + 1
		stretch_shrink = taille_pixels
