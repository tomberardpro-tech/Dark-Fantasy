extends Node
## Les bruitages du jeu (autoload « Sons »). Exemple : Sons.jouer("coup_poing", position).
##
## Pour que ce soit agréable et jamais répétitif :
## - chaque son a plusieurs variantes, tirées au hasard sans rejouer deux fois la même ;
## - la hauteur et le volume changent un peu à chaque fois ;
## - un même son ne peut pas se superposer à lui-même trop vite ;
## - les sons placés dans le monde s'entendent depuis le héros (pas depuis la caméra).
##
## Sons enregistrés : packs Kenney « Impact Sounds » et « RPG Audio » (CC0, assets/sons).
## Sons fabriqués ici (absents des packs) : souffles d'épée, râle des squelettes, éclaboussures,
## tintement, et les boucles d'ambiance du feu, de l'eau et du vent.

const DOSSIER := "res://assets/sons/"
const FREQUENCE := 22050

## nom → [variantes (fichiers ou sons fabriqués), volume en dB, hauteur min, hauteur max].
var _banque := {}
## Le dernier numéro de variante joué, et quand, pour chaque son.
var _derniere := {}
var _dernier_moment := {}
var _lecteurs_3d: Array[AudioStreamPlayer3D] = []
var _lecteurs_2d: Array[AudioStreamPlayer] = []
var _monde: Node
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Les sons de l'interface (la lettre) marchent aussi quand le jeu est en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_preparer_mixage()
	_ranger("souffle_epee", [_souffle(0.26, 1), _souffle(0.3, 2), _souffle(0.24, 3), _souffle(0.28, 4)], -7.0, 0.92, 1.08)
	_ranger("souffle_poing", [_souffle(0.16, 5), _souffle(0.18, 6), _souffle(0.15, 7)], -13.0, 1.3, 1.5)
	_ranger("souffle_lourd", [_souffle(0.5, 8), _souffle(0.55, 9)], -5.0, 0.7, 0.8)
	_ranger("coup_epee", _fichiers("impactWood_medium_00", 5), -2.0, 0.85, 1.05)
	_ranger("tinte_lame", _fichiers("impactMetal_light_00", 5), -15.0, 1.1, 1.3)
	_ranger("coup_poing", _fichiers("impactPunch_medium_00", 5), -3.0, 0.9, 1.1)
	_ranger("coup_poing_lourd", _fichiers("impactPunch_heavy_00", 5), -1.0, 0.85, 1.0)
	_ranger("impact_sol", _fichiers("impactSoft_heavy_00", 5), 0.0, 0.65, 0.75)
	_ranger("impact_sol_bois", _fichiers("impactWood_heavy_00", 5), -6.0, 0.55, 0.65)
	_ranger("degainer", ["drawKnife1", "drawKnife2", "drawKnife3"], -6.0, 0.8, 0.9)
	_ranger("ranger", ["metalLatch", "metalClick"], -8.0, 0.85, 0.95)
	_ranger("tissu", ["cloth1", "cloth2", "cloth3", "cloth4"], -12.0, 0.9, 1.1)
	_ranger("heros_touche", _fichiers("impactPunch_medium_00", 5), -4.0, 0.7, 0.8)
	_ranger("chute", _fichiers("impactSoft_medium_00", 5), -3.0, 0.7, 0.8)
	_ranger("pas_terre", _fichiers("footstep_grass_00", 5), -15.0, 0.85, 1.0)
	_ranger("pas_bois", _fichiers("footstep_wood_00", 5), -11.0, 0.9, 1.05)
	_ranger("pas_eau", [_eclaboussure(1), _eclaboussure(2), _eclaboussure(3), _eclaboussure(4)], -11.0, 0.9, 1.15)
	_ranger("os_cliquetis", _fichiers("impactWood_light_00", 5), -13.0, 1.6, 2.1)
	_ranger("os_choc", _fichiers("impactPlank_medium_00", 5), -8.0, 1.2, 1.5)
	_ranger("rale", [_rale(1), _rale(2), _rale(3)], -9.0, 0.85, 1.1)
	_ranger("grincement", ["creak1", "creak2", "creak3"], -7.0, 0.85, 0.95)
	_ranger("loquet", ["metalLatch"], -6.0, 0.95, 1.05)
	_ranger("tintement", [_tintement(1), _tintement(2)], -12.0, 0.95, 1.05)
	_ranger("papier", ["bookOpen"], -6.0, 1.0, 1.1)
	_ranger("papier_ferme", ["bookFlip1", "bookFlip2", "bookFlip3"], -8.0, 1.0, 1.1)
	_ranger("feu", [_boucle_feu()], 0.0, 1.0, 1.0)
	_ranger("eau", [_boucle_eau()], 0.0, 1.0, 1.0)
	_ranger("vent", [_boucle_vent()], 0.0, 1.0, 1.0)


## Joue un son. « ou » : une position (Vector3), un nœud 3D, ou rien (son d'interface).
func jouer(nom: String, ou: Variant = null, volume := 0.0, hauteur := 1.0) -> void:
	if not _banque.has(nom):
		return
	# Pas deux fois le même son en moins de 40 ms (évite les doubles déclenchements).
	var maintenant := Time.get_ticks_msec()
	if maintenant - int(_dernier_moment.get(nom, -1000)) < 40:
		return
	_dernier_moment[nom] = maintenant
	var son: Array = _banque[nom]
	var variantes: Array = son[0]
	var numero := _rng.randi_range(0, variantes.size() - 1)
	if variantes.size() > 1 and numero == _derniere.get(nom, -1):
		numero = (numero + 1 + _rng.randi_range(0, variantes.size() - 2)) % variantes.size()
	_derniere[nom] = numero
	var flux: AudioStream = variantes[numero]
	var vol: float = son[1] + volume + _rng.randf_range(-1.5, 1.0)
	var haut: float = _rng.randf_range(son[2], son[3]) * hauteur
	var position: Variant = ou
	if ou is Node3D:
		position = (ou as Node3D).global_position
	if position is Vector3 and _preparer_monde():
		var lecteur := _lecteur_3d()
		lecteur.global_position = position
		lecteur.stream = flux
		lecteur.volume_db = vol
		lecteur.pitch_scale = haut
		lecteur.play()
	else:
		var lecteur := _lecteur_2d()
		lecteur.stream = flux
		lecteur.volume_db = vol
		lecteur.pitch_scale = haut
		lecteur.play()


## Joue un son un peu plus tard (en secondes), par exemple pour caler un souffle d'épée.
func jouer_apres(delai: float, nom: String, ou: Variant = null, volume := 0.0, hauteur := 1.0) -> void:
	if delai <= 0.0:
		jouer(nom, ou, volume, hauteur)
		return
	await get_tree().create_timer(delai).timeout
	jouer(nom, ou, volume, hauteur)


## Une série de petits sons rapprochés (os qui s'entrechoquent, qui s'effondrent…).
func serie(nom: String, ou: Variant, nombre: int, duree: float, volume := 0.0) -> void:
	for i in nombre:
		jouer_apres(_rng.randf_range(0.0, duree), nom, ou, volume - i * 0.4)
		# Pour que la limite de 40 ms ne mange pas les sons de la série.
		_dernier_moment[nom] = -1000


## Un son qui tourne en boucle, attaché à un nœud 3D (feu, ruisseau) : il s'entend de près.
func boucle(nom: String, parent: Node3D, volume := 0.0, portee := 14.0) -> AudioStreamPlayer3D:
	var lecteur := AudioStreamPlayer3D.new()
	lecteur.stream = (_banque[nom][0] as Array)[0]
	lecteur.volume_db = volume
	lecteur.unit_size = portee * 0.35
	lecteur.max_distance = portee * 2.0
	lecteur.bus = "Ambiance"
	lecteur.autoplay = true
	parent.add_child(lecteur)
	return lecteur


## Une boucle sans position (le vent, partout).
func boucle_partout(nom: String, volume := 0.0) -> AudioStreamPlayer:
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = (_banque[nom][0] as Array)[0]
	lecteur.volume_db = volume
	lecteur.autoplay = true
	lecteur.bus = "Ambiance"
	add_child(lecteur)
	return lecteur


# --- Mixage ---------------------------------------------------------------------

## Trois canaux séparés, réglables chacun : la musique, les bruitages, l'ambiance.
## Les bruitages passent dans un compresseur (les coups forts ne couvrent pas tout, les
## petits sons restent audibles) et une légère réverbération de sous-bois (tout sonne dans
## le même lieu). Un limiteur général empêche toute saturation.
const VOLUME_MUSIQUE := 0.0
const VOLUME_BRUITAGES := -5.0
const VOLUME_AMBIANCE := -2.0


func _preparer_mixage() -> void:
	if AudioServer.get_bus_index("Bruitages") >= 0:
		return
	var compresseur := AudioEffectCompressor.new()
	compresseur.threshold = -16.0
	compresseur.ratio = 3.0
	compresseur.attack_us = 4000.0
	compresseur.release_ms = 140.0
	var reverb := AudioEffectReverb.new()
	reverb.room_size = 0.35
	reverb.damping = 0.6
	reverb.wet = 0.08
	reverb.dry = 1.0
	_canal("Musique", VOLUME_MUSIQUE, [])
	_canal("Bruitages", VOLUME_BRUITAGES, [compresseur, reverb])
	_canal("Ambiance", VOLUME_AMBIANCE, [])
	var limiteur := AudioEffectHardLimiter.new()
	limiteur.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiteur)


func _canal(nom: String, volume: float, effets: Array) -> void:
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, nom)
	AudioServer.set_bus_volume_db(i, volume)
	AudioServer.set_bus_send(i, "Master")
	for effet in effets:
		AudioServer.add_bus_effect(i, effet)


# --- Lecteurs -------------------------------------------------------------------

## Les sons 3D vivent dans le monde du jeu (le même que le héros).
func _preparer_monde() -> bool:
	if is_instance_valid(_monde):
		return true
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	if joueur == null:
		return false
	_monde = joueur.get_parent()
	_lecteurs_3d.clear()
	return true


func _lecteur_3d() -> AudioStreamPlayer3D:
	for l in _lecteurs_3d:
		if not l.playing:
			return l
	var l := AudioStreamPlayer3D.new()
	l.unit_size = 5.0
	l.max_distance = 45.0
	l.attenuation_filter_cutoff_hz = 12000.0
	l.bus = "Bruitages"
	_monde.add_child(l)
	_lecteurs_3d.append(l)
	return l


func _lecteur_2d() -> AudioStreamPlayer:
	for l in _lecteurs_2d:
		if not l.playing:
			return l
	var l := AudioStreamPlayer.new()
	l.bus = "Bruitages"
	add_child(l)
	_lecteurs_2d.append(l)
	return l


func _ranger(nom: String, variantes: Array, volume: float, hauteur_min: float, hauteur_max: float) -> void:
	var flux := []
	for v in variantes:
		if v is String:
			var chemin: String = DOSSIER + v + ".ogg"
			if ResourceLoader.exists(chemin):
				flux.append(load(chemin))
		else:
			flux.append(v)
	if not flux.is_empty():
		_banque[nom] = [flux, volume, hauteur_min, hauteur_max]


func _fichiers(debut: String, nombre: int) -> Array:
	var liste := []
	for i in nombre:
		liste.append(debut + str(i))
	return liste


# --- Sons fabriqués --------------------------------------------------------------

func _wav(echantillons: PackedFloat32Array, en_boucle := false) -> AudioStreamWAV:
	var octets := PackedByteArray()
	octets.resize(echantillons.size() * 2)
	for i in echantillons.size():
		octets.encode_s16(i * 2, int(clampf(echantillons[i], -1.0, 1.0) * 32000.0))
	var son := AudioStreamWAV.new()
	son.format = AudioStreamWAV.FORMAT_16_BITS
	son.mix_rate = FREQUENCE
	son.stereo = false
	son.data = octets
	if en_boucle:
		son.loop_mode = AudioStreamWAV.LOOP_FORWARD
		son.loop_end = echantillons.size()
	return son


## Le souffle d'une lame qui fend l'air : un bruit dont le timbre monte puis redescend.
func _souffle(duree: float, graine: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = graine
	var n := int(duree * FREQUENCE)
	var s := PackedFloat32Array()
	s.resize(n)
	var bas := 0.0
	var bas2 := 0.0
	for i in n:
		var t := float(i) / n
		# L'enveloppe : monte vite, culmine aux deux cinquièmes, s'éteint doucement.
		var env := pow(sin(PI * pow(t, 0.7)), 2.0)
		var coupure := 400.0 + 3200.0 * env
		var a := 1.0 - exp(-TAU * coupure / FREQUENCE)
		bas += a * (rng.randf_range(-1.0, 1.0) - bas)
		bas2 += a * (bas - bas2)
		s[i] = bas2 * env * 2.6
	return _wav(s)


## Le râle d'un squelette : un souffle rauque et grave qui grince.
func _rale(graine: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = graine * 31
	var duree := 0.8 + graine * 0.12
	var n := int(duree * FREQUENCE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	var bas := 0.0
	for i in n:
		var t := float(i) / n
		var env := sin(PI * t) * (0.7 + 0.3 * sin(t * 40.0 + graine))
		var freq := 55.0 + 15.0 * sin(t * 7.0 + graine) + rng.randf_range(-6.0, 6.0)
		phase = fmod(phase + freq / FREQUENCE, 1.0)
		var dent := phase * 2.0 - 1.0
		var x := dent * 0.6 + rng.randf_range(-1.0, 1.0) * 0.5
		bas += 0.18 * (x - bas)
		s[i] = bas * env * 1.6
	return _wav(s)


## Un pas dans l'eau peu profonde : un petit jet de bruit clair et une bulle.
func _eclaboussure(graine: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = graine * 7
	var n := int(0.22 * FREQUENCE)
	var s := PackedFloat32Array()
	s.resize(n)
	var bas := 0.0
	var bulle := 500.0 + graine * 90.0
	for i in n:
		var t := float(i) / n
		var bruit := rng.randf_range(-1.0, 1.0)
		bas += 0.3 * (bruit - bas)
		var clair := (bruit - bas) * exp(-t * 14.0)
		var bloup := sin(TAU * bulle * (1.0 + t * 0.8) * t * 0.22) * exp(-t * 25.0) * 0.4
		s[i] = (clair * 0.8 + bloup) * min(t * 60.0, 1.0)
	return _wav(s)


## Un tintement clair (l'épée qui sort du coffre).
func _tintement(graine: int) -> AudioStreamWAV:
	var n := int(1.2 * FREQUENCE)
	var s := PackedFloat32Array()
	s.resize(n)
	var f := 1320.0 + graine * 220.0
	for i in n:
		var t := float(i) / FREQUENCE
		s[i] = (sin(TAU * f * t) + 0.5 * sin(TAU * f * 2.01 * t) + 0.25 * sin(TAU * f * 3.03 * t)) * exp(-t * 3.5) * 0.25
	return _wav(s)


## Recolle la fin d'une boucle sur son début pour qu'on n'entende pas la jointure.
func _sans_couture(s: PackedFloat32Array, fondu: int) -> PackedFloat32Array:
	var n := s.size() - fondu
	var r := PackedFloat32Array()
	r.resize(n)
	for i in n:
		r[i] = s[i]
	for i in fondu:
		var k := float(i) / fondu
		r[i] = s[n + i] * (1.0 - k) + s[i] * k
	return r


## Le feu : un grondement doux et des crépitements au hasard.
func _boucle_feu() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var n := int(6.5 * FREQUENCE)
	var s := PackedFloat32Array()
	s.resize(n)
	var bas := 0.0
	for i in n:
		bas += 0.02 * (rng.randf_range(-1.0, 1.0) - bas)
		s[i] = bas * 0.9
	# Les crépitements : de petits éclats secs, plus ou moins forts.
	for c in 70:
		var debut := rng.randi_range(0, n - 2000)
		var force := rng.randf_range(0.15, 0.6)
		var longueur := rng.randi_range(150, 900)
		var prec := 0.0
		for i in longueur:
			var x := rng.randf_range(-1.0, 1.0)
			var clair := x - prec
			prec = x
			s[debut + i] += clair * force * exp(-float(i) / longueur * 6.0)
	return _wav(_sans_couture(s, int(0.5 * FREQUENCE)), true)


## Le ruisseau : un bruissement continu qui ondule, avec des glouglous.
func _boucle_eau() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var n := int(7.0 * FREQUENCE)
	var s := PackedFloat32Array()
	s.resize(n)
	var bas := 0.0
	var tres_bas := 0.0
	for i in n:
		var t := float(i) / FREQUENCE
		var x := rng.randf_range(-1.0, 1.0)
		bas += 0.25 * (x - bas)
		tres_bas += 0.03 * (bas - tres_bas)
		var bande := bas - tres_bas
		s[i] = bande * (0.55 + 0.25 * sin(t * 1.3) + 0.2 * sin(t * 3.7 + 1.0))
	for g in 45:
		var debut := rng.randi_range(0, n - 4000)
		var f := rng.randf_range(250.0, 700.0)
		var longueur := rng.randi_range(800, 2600)
		for i in longueur:
			var k := float(i) / longueur
			s[debut + i] += sin(TAU * f * (1.0 + k * 0.6) * float(i) / FREQUENCE) * sin(PI * k) * 0.12
	return _wav(_sans_couture(s, int(0.6 * FREQUENCE)), true)


## Le vent dans les arbres : un souffle grave qui monte et retombe lentement.
func _boucle_vent() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	var n := int(10.0 * FREQUENCE)
	var s := PackedFloat32Array()
	s.resize(n)
	var bas := 0.0
	var bas2 := 0.0
	for i in n:
		var t := float(i) / FREQUENCE
		var rafale := 0.5 + 0.3 * sin(t * 0.63) + 0.2 * sin(t * 1.7 + 2.0)
		var a := 0.01 + 0.03 * rafale
		bas += a * (rng.randf_range(-1.0, 1.0) - bas)
		bas2 += a * (bas - bas2)
		s[i] = bas2 * rafale * 6.0
	return _wav(_sans_couture(s, int(1.0 * FREQUENCE)), true)
