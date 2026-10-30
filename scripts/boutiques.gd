class_name Boutiques
## Ce que vendent les marchands de Bruneval, et à quel prix (en pièces d'or).
## Les prix sont faits pour qu'au début on puisse regarder mais pas encore acheter : il faut
## d'abord ramasser l'or que lâchent les monstres. Tom pourra changer les prix et les effets ici.
##
## Pour chaque objet : son nom, sa sorte (« arme », « armure », « potion »), son prix, sa
## description, et son effet :
## - arme : « degats » = multiplicateur des dégâts, « teinte » = couleur de la lame ;
## - armure : « protection » = part des dégâts reçus évitée, « teinte » = couleur de la tenue ;
## - potion : « soin » (points de vie rendus), ou « force » / « resistance » (pendant
##   « duree » secondes).

const FORGERON := [
	{"nom": "Épée de fer", "sorte": "arme", "prix": 60, "degats": 1.3, "teinte": Color(0.78, 0.78, 0.84),
		"description": "Une lame solide, sans une trace de rouille. Dégâts +30 %."},
	{"nom": "Épée d'acier noirci", "sorte": "arme", "prix": 140, "degats": 1.6, "teinte": Color(0.34, 0.34, 0.42),
		"description": "Forgée de nuit et trempée dans l'eau du puits. Dégâts +60 %."},
	{"nom": "Armure de cuir", "sorte": "armure", "prix": 80, "protection": 0.2, "teinte": Color(0.56, 0.43, 0.32),
		"description": "Du cuir épais, cousu à la main. Dégâts reçus −20 %."},
	{"nom": "Cotte de mailles", "sorte": "armure", "prix": 160, "protection": 0.35, "teinte": Color(0.5, 0.52, 0.58),
		"description": "Des anneaux d'acier serrés, lourds mais sûrs. Dégâts reçus −35 %."},
]

const MEDECIN := [
	{"nom": "Potion de soin", "sorte": "potion", "prix": 15, "soin": 40.0,
		"description": "Rend 40 points de vie. À boire avec A (ou 1)."},
	{"nom": "Grande potion de soin", "sorte": "potion", "prix": 35, "soin": 100.0,
		"description": "Rend toute ta vie. À boire avec A (ou 1) quand tu es bien blessé."},
	{"nom": "Potion de force", "sorte": "potion", "prix": 25, "force": 0.25, "duree": 60.0,
		"description": "Dégâts +25 % pendant une minute. À boire avec 2."},
	{"nom": "Potion de résistance", "sorte": "potion", "prix": 25, "resistance": 0.25, "duree": 60.0,
		"description": "Dégâts reçus −25 % pendant une minute. À boire avec 3."},
]


static func catalogue(boutique: String) -> Array:
	return FORGERON if boutique == "forgeron" else MEDECIN
