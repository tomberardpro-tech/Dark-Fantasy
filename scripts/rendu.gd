extends SubViewportContainer
## Effet « 3D pixel » : le monde est calculé en plus petit, puis agrandi sans lissage
## (gros pixels nets), et la palette commune est appliquée par-dessus.
## Pour comparer en jouant : F1 = palette oui/non, F2 = taille des pixels (1 à 4).
## La molette de la souris rapproche ou éloigne la caméra.

## Taille d'un pixel du jeu, en pixels de l'écran (1 = pas d'effet pixel).
@export_range(1, 8) var taille_pixels := 2


func _ready() -> void:
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
