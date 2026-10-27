# Contexte du jeu : Jeu Dark Fantasy (nom à définir)

Ce fichier décrit le jeu et les décisions déjà prises. Lis-le en entier avant chaque tâche,
et mets-le à jour quand Tom prend une nouvelle décision.

## Avec qui tu travailles

- **Tom**, le créateur du jeu. Il débute et ne sait pas coder : il construit le jeu par prompts.
- Parle-lui en **français**, simplement, sans jargon. Explique ce que tu fais en quelques phrases.
- Avance par **toutes petites étapes**, chacune testable. Après chaque étape, dis-lui comment tester.
- Ne casse pas ce qui marche : si une modification est risquée, explique-le avant de la faire.
- Quand une étape fonctionne, enregistre-la avec git (message en français).
- **Ne lance jamais de fenêtre du jeu sur l'ordinateur de Tom** pour tester : il travaille sur autre
  chose pendant ce temps. Teste sans affichage quand c'est possible. Pour juger le rendu, c'est Tom
  qui lance le jeu et qui dit ce qu'il voit.
- Pas de notifications Windows : Tom les a désactivées, ne jamais les réactiver.
- Demande toujours à Tom avant de télécharger un pack d'assets.
- Tom aime qu'on lui **pose des questions** (avec des choix) pour bien visualiser avant de construire.
- Git : nom « Tom », e-mail tomberardpro@gmail.com. Tom a un compte GitHub.

## L'histoire

> Un dieu décide d'effacer l'humanité en lançant une malédiction sur le monde. Le monde s'est
> assombri, des monstres sont apparus. Il ne reste qu'une chose à faire : protéger les
> survivants et venir à bout de ce dieu.

Phrase d'accroche : « Un dieu a maudit le monde pour effacer l'humanité ; tant qu'il reste des
survivants à protéger, il reste un dieu à abattre. »

- Le héros est **amnésique** : il se réveille près d'un feu de camp sans souvenir. On découvre qui
  il est en jouant.
- Il fait **toujours nuit** dans le monde maudit.

## Le concept

| | |
| --- | --- |
| Genre | Dark fantasy, action-RPG |
| Mode | **Solo**. Ne rien construire pour le multijoueur (la coop est mise de côté). |
| Monde | Monde ouvert à explorer |
| Vue | **3D en vue isométrique, caméra fixe** (façon Diablo), **même angle que la maquette** (Tom y tient), mais **en vraie perspective** (la vue sans perspective lui semblait trop « plate ») |
| Contrôles | ZQSD (clavier AZERTY) **ou** clic de souris pour se déplacer, Maj pour courir, Espace pour une **roulade**, E pour interagir |
| Sauvegarde | Uniquement aux feux de camp |
| Progression | Quêtes, expérience, arbre de compétences, nouvelles tenues |
| Classes | Guerrier, Mage, Nécromancien, Archer (nom à trouver : Traqueur ? Rôdeur ? Veilleur ?). **Le moment du choix de la classe sera décidé plus tard.** |
| Objectif final | Vaincre 5 boss, récupérer leurs 5 reliques, ouvrir la Grande Porte des Dieux, vaincre le dieu |
| Moteur | **Godot 4, dernière version stable** |
| Écran | Rien à l'écran pour l'instant (pas de barre de vie), sauf les messages d'action (« E : s'asseoir ») et une **petite boussole** en haut qui indique où aller |

## Le monde

- **La zone de départ** se trouve **avant la Zone 1**. Le terrain est **plat pour l'instant** :
  1. Le jeu commence de nuit, sans intro : le personnage est **assis sur un tronc près d'un feu de
     camp**, dans une **clairière au milieu d'une forêt** de pins et d'arbres morts.
  2. Il suit un **chemin dans la forêt** (environ 1 minute de marche).
  3. Il arrive au **hameau de Bruneval**, où vivent des survivants.
- **5 zones**, chacune avec un boss et une relique (noms à définir).
- **La Grande Porte des Dieux** : au sommet d'une montagne, avec une lueur rouge.
  **Pour l'instant (décision de Tom) : rien au loin.** Elle sera ajoutée plus tard.

### La clairière

Clairière de taille moyenne au milieu des pins et des arbres morts tordus. Au centre, le feu de
camp (pierres, bûches, flammes, braises) et un tronc pour s'asseoir. Un vieil arbre mort au bord.
Rien d'autre autour du feu. Ce feu sert de point de sauvegarde.

### Le chemin dans la forêt

Un sentier de terre plat qui serpente entre les arbres, bordé de lanternes. Le long du chemin :
- une **ruine** couverte de mousse (décor) ;
- un **ruisseau** à l'eau sombre et calme qui reflète la lune, avec un petit **pont de bois** ;
- un **autel abandonné** avec une lueur rouge, premier signe de la malédiction (décor) ;
- une **charrette renversée** qu'on peut fouiller (E) : on y trouve une **vieille épée**, la
  première arme du joueur.

Pas d'ennemi pour l'instant.

### Le hameau de Bruneval

Un **hameau de 4 à 6 maisons**, des **abris de fortune** rafistolés avec des planches, tournés vers
une place. Une **palissade rafistolée** (elle a déjà été attaquée) avec une entrée et des torches là
où arrive le chemin. Sur la place : un feu de camp (deuxième point de sauvegarde) et le puits. Chemin
de terre boueux avec des flaques, fenêtres éclairées.

- **On peut entrer dans toutes les maisons.** Entrer fait passer à un nouvel écran, une pièce à part
  (comme dans Pokémon).
- Maisons prévues : une **auberge**, un **forgeron**, un **médecin** (noms des personnages : Tom les
  choisira).

Les survivants « vivent un peu » :
- **Maren** : mystérieuse, elle semble en savoir beaucoup sur le dieu et la malédiction ;
- **Bran** : monte la garde à l'entrée de la palissade, avec une torche ;
- **Élise** : va et vient entre le puits et une maison pour porter de l'eau ;
- **le vieux Hugo** : assis au feu de la place, il raconte des histoires ;
- **Osric** : le marchand, il range ses objets à son étal sous un auvent.

## Direction artistique : la « 3D pixel » légère

- Vraie 3D, vue isométrique. **Effet pixel réduit à la demande de Tom : taille 1 par défaut (F2 pour comparer), palette commune et tramage discret gardés.** Ancien réglage :
  léger** (pixels de taille 2 sur la maquette) : l'image reste détaillée avec un côté rétro.
- Modèles low poly.
- **Palette limitée** : bleus nuit et violets pour l'ensemble ; touches chaudes orange pour les
  feux, torches et fenêtres (le feu est le seul accent vif) ; **rouge réservé à la malédiction et
  au dieu** (quand le rouge apparaît, le dieu est proche).
- **Jamais de couleurs vives ou saturées.** Tom n'aime pas l'herbe verte « mignonne » ni le bleu
  trop vif : végétation vert-gris éteint, bois brun-gris sombre, roche gris froid, sol sombre.
- **Palette commune pour tout** : chaque modèle importé est désaturé, assombri et teinté vers la
  palette, pour que tout reste cohérent même avec des packs différents.
- Ambiance : **nuit bleue lisible** (clair de lune bleu, on voit bien le décor), éclairages chauds et
  contrastés autour des feux et des lanternes.
- Le personnage au départ : un **voyageur encapuchonné** (cape sombre, capuche, tenue simple).
- Maquettes de référence (vues et carte) : https://claude.ai/artifact/XT4fjcwino5JMEwKefJbF2
- Références de Tom : une vidéo de jeu en 3D pixel (nuit violette, gros pixels, épée en main) et
  une image d'un village de nuit en pixel art détaillé.

### Les sons

Dès la clairière : le **feu qui crépite** (plus fort quand on est près), la **forêt la nuit** (vent
dans les pins, chouette, insectes) et une **musique douce**, calme et un peu triste.

### Le dieu (à affiner)

Corps humain altéré, peau pâle fissurée comme de la porcelaine avec des coutures, longs cheveux
noirs, yeux rouges, un troisième œil sur le front, tentacules noirs couverts d'yeux derrière lui.
Couleurs : noir, gris et rouge sang.

## Assets

- **Pack principal : Quaternius** (gratuit, licence CC0, très connu). Packs utiles :
  **Stylized Nature MegaKit** (pins, arbres morts, rochers, herbes, fougères), **Medieval Village
  MegaKit** (village), **Modular Character Outfits Fantasy** et **Universal Animation Library**
  (personnages animés), **Animal Pack** (loups).
- **Déjà téléchargé** : Stylized Nature MegaKit [Standard] (gratuit), dans `assets/nature/`
  (seulement les modèles utilisés ; le pack complet est dans `Téléchargements\Quaternius_Nature`).
- **Déjà téléchargé** : Universal Base Characters, Modular Character Outfits Fantasy et
  Universal Animation Library [Standard] (gratuits). Le héros utilise la tenue **Male_Ranger**
  (avec capuche) et les animations UAL1, dans `assets/personnage/` (textures réduites à 1024 px).
  Les packs complets sont dans `Téléchargements\Quaternius_Personnages`.
- Si besoin de grain sur le sol, la roche ou le bois : textures **Kenney Retro Textures Fantasy**
  ou **Screaming Brain Studios Tiny Texture Pack** (CC0).
- Écarté : Synty POLYGON Dark Fantasy (payant).
- **Déjà téléchargé** : Medieval Village MegaKit et Fantasy Props MegaKit [Standard] (gratuits),
  dans `assets/objets/` (seulement les objets utilisés, textures réduites à 1024 px) : lanternes,
  torches, pont, charrette, ruine, caisses, épée. Tom a accepté de reprendre le Fantasy Props
  MegaKit pour les objets du chemin. Packs complets dans `Téléchargements\Quaternius_Village`.
- Tom veut de **vrais objets**, pas des cubes : utiliser les modèles des packs dès que possible.
- Tom n'aime pas (retirés) : les fougères, les buissons et grandes plantes (Bush_Common,
  Plant_1, Plant_7), les pierres plates au bord du sentier (RockPath).
- Packs déjà essayés puis retirés à la demande de Tom : Quaternius Ultimate Modular Ruins,
  Kenney Survival Kit.
- Toujours vérifier la licence d'un pack avant de l'utiliser.
