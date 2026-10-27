class_name Vent
## Le vent de la nuit : une brise légère avec des rafales irrégulières.
## Tous les objets (flammes, braises, arbres, herbes) lui demandent sa force au même moment,
## pour que tout bouge ensemble.

## D'où souffle le vent, au sol (vers où il pousse).
const DIRECTION := Vector3(0.8, 0.0, 0.6)
## Force de la brise de base (0 = aucun vent).
const BRISE := 0.35

static var _bruit: FastNoiseLite


## Force du vent (de 0 à environ 1) à un instant et à un endroit donnés.
## Les rafales traversent la clairière : elles n'arrivent pas partout en même temps.
static func force(temps: float, position: Vector3 = Vector3.ZERO) -> float:
	if _bruit == null:
		_bruit = FastNoiseLite.new()
		_bruit.seed = 11
		_bruit.frequency = 0.15
	var decalage := position.dot(DIRECTION) * 0.08
	var rafale := (_bruit.get_noise_1d(temps - decalage) + 1.0) * 0.5
	return BRISE + rafale * rafale * 0.65


## Le vent sous forme de flèche : direction × force.
static func souffle(temps: float, position: Vector3 = Vector3.ZERO) -> Vector3:
	return DIRECTION.normalized() * force(temps, position)
