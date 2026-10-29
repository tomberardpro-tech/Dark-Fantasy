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
| Contrôles | **Pas de déplacement à la souris.** ZQSD pour marcher, Maj courir, Espace roulade. **Clic gauche = coup d'épée** droit devant (direction de la course ; l'épée sort toute seule), recliquer = 2e coup différent (combo de 2). **Clic droit = saut, épée au-dessus de la tête, abattue au sol** : repousse les ennemis autour. E interagir, R sortir/ranger l'épée. On peut courir en frappant ; sur place, coups et saut avancent un peu. Traînée lumineuse sur la lame, chiffres de dégâts. Gestes d'épée : pack Mixamo « Sword and Shield » (sur le mannequin Y Bot) converti par `outils/convertir_mixamo.gd` vers `assets/mixamo/epee_heros.res` ; **ces fichiers ne vont pas sur GitHub** (droits Mixamo) : sans eux le jeu reprend les anciens coups. |
| Sauvegarde | Uniquement aux feux de camp. **Coupée sur le disque pendant la fabrication** (Tom repart de zéro à chaque lancement) : `SUR_LE_DISQUE` dans `scripts/sauvegarde.gd`. |
| Progression | Quêtes, expérience, arbre de compétences, nouvelles tenues |
| Classes | Guerrier, Mage, Nécromancien, Archer (nom à trouver : Traqueur ? Rôdeur ? Veilleur ?). **Le moment du choix de la classe sera décidé plus tard.** |
| Objectif final | Vaincre 5 boss, récupérer leurs 5 reliques, ouvrir la Grande Porte des Dieux, vaincre le dieu |
| Moteur | **Godot 4, dernière version stable** |
| Écran | Une **petite barre de vie** en bas à gauche, les messages d'action (« E : … ») et les annonces. Plus de boussole (retirée à la demande de Tom). Police **Cinzel** (OFL) pour tous les textes. |

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

Un sentier de terre battue plat qui serpente entre les arbres (virages doux, largeur qui varie, bords irréguliers mangés par la forêt, boue dans les creux et près du ruisseau, quelques flaques mates, cailloux et racines discrets ; aspect dans `shaders/chemin.gdshader`), bordé de lanternes. Le long du chemin :
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
- Le personnage : tenue **Paysan** (toile, simple), **sans capuche**, avec des **cheveux longs noirs** (choix de Tom).
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
  Universal Animation Library [Standard] (gratuits). Le héros porte la tenue **Male_Peasant**, la tête du corps de base et **Hair_Long** (choix de Tom),
  et les animations UAL1, dans `assets/personnage/` (textures réduites à 1024 px).
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
  Plant_1, Plant_7), les pierres plates au bord du sentier (RockPath), un sol à bosses qui
  brille par petits points (« effet miroir »), le trèfle (Clover).
- Sol : terre brune sombre et lisse (plus marron près du feu, demande de Tom), seulement de
  grandes variations très douces, sans texture
  (image de référence de Tom). Palette commune coupée par défaut pour coller à cette image
  (F1 la remet).
- Packs déjà essayés puis retirés à la demande de Tom : Quaternius Ultimate Modular Ruins,
  Kenney Survival Kit.
- Toujours vérifier la licence d'un pack avant de l'utiliser.

## Disposition du décor : figée

- **Ne jamais déplacer le décor sans que Tom le demande.** La place de chaque arbre, rocher,
  herbe et champignon est figée dans `donnees/foret.json` (créé une fois, puis toujours rechargé).
- Pour retirer ou ajouter quelque chose, modifier seulement les entrées concernées de ce
  fichier, sans relancer le tirage au hasard (qui décalerait tout le reste).

## Ajouts récents (zone de départ)

- **Coffre** près du tronc de la clairière (Chest_Wood) : E l'ouvre, on y trouve la vieille épée.
  La **charrette** n'est plus qu'un décor.
- **3 squelettes** fabriqués os par os sur le squelette d'animation du héros (même DA, os fins,
  orbites rougeoyantes, épée rouillée), difficulté moyenne, allongés juste après le
  pont : ils se relèvent quand on approche, poursuivent et frappent, et s'effondrent en tas
  d'os. Si le héros meurt, il se
  réveille assis au dernier feu de camp avec toute sa vie, et les squelettes se rendorment.
- La ruine est remplacée par une **cabane à moitié effondrée** (pièces du Medieval Village MegaKit).
- Le tronc pour s'asseoir est un **rondin simple** (choix de Tom) : bien rond, net, plus court, écorce et cernes aux bouts.
- **Cheveux longs noirs** qui bougent avec les mouvements et le vent.
- **Musique** douce : « Lament for a Warrior's Soul » (RandomMind, CC0), partout au même volume,
  en boucle sans trou.
- **Carte refaite (maquette validée par Tom)** : le chemin part juste derrière le coffre et monte presque tout droit vers le haut de l'écran jusqu'à Bruneval (environ 130 m). Dans l'ordre : cabane à gauche, ruisseau qui traverse l'écran de gauche à droite avec le pont, squelettes, autel à droite, charrette à gauche, Bruneval. La clairière n'a pas bougé ; la forêt du chemin a été replantée puis figée. Le ruisseau a une vraie matière (courant, reflets, mousse aux berges).
- **Coffre** : il tremble, le couvercle se soulève lentement, une lueur dorée et une poussière
  brillante s'en échappent, puis l'épée s'élève en tournant avant de rejoindre le dos du héros.
- **Poings** (sans épée) : trois coups qui s'enchaînent en recliquant (direct gauche, direct
  droit, crochet qui repousse). Tout coup qui touche fait un très court ralenti (impact).
- **Feu** : flammes en particules (jaunes au cœur, rouges en montant), fumée sombre, lit de braises qui
  rougeoient, bûches en écorce noircie.
- **Barre de vie verte.** **Repère sobre en haut de l'écran** (trait orné, losange, chevron vers la
  destination), sans nom : en arrivant, « Bruneval » apparaît en grand puis s'efface.
- Terre : **légère texture** de mottes et de grain, mate (essai, réglage `texture_terre` dans
  `shaders/sol.gdshader`, 0 = sol lisse comme avant).
- L'épée est serrée au creux du poing (avant, elle passait au ras des jointures).
- **Cabane de l'écrivain** juste avant Bruneval (à droite du chemin, ouverte vers la caméra,
  moitié du toit tombée) : table d'écrivain, chaise, bougie, livres, parchemin, et une
  **lettre de Maren** sous un faisceau de lumière dorée. E : la lettre s'affiche en grand sur
  un parchemin (jeu en pause, E pour refermer) ; le faisceau s'éteint une fois lue. Système
  réutilisable pour tous les objets d'information (`scripts/lettre.gd`). Texte modifiable dans
  `scripts/abri_ecrivain.gd`.
- **Parcours linéaire** : forêt resserrée de chaque côté du chemin, limites invisibles à 12 m
  du chemin et autour de la clairière (ouverte seulement vers le chemin).
- **On peut marcher dans le ruisseau.** **Nouveau pont** fait main : troncs sur des pierres,
  planches inégales légèrement bombées (quelques-unes manquent), rambarde en rondins.
- **Bruitages** (autoload `Sons`, `scripts/sons.gd`) : packs Kenney « Impact Sounds » et « RPG
  Audio » (CC0, `assets/sons`) + sons fabriqués dans le jeu (souffles d'épée, râle, éclaboussures,
  tintement, boucles feu / ruisseau / vent). Variantes au hasard sans répétition, petites
  variations de hauteur et de volume, écoute depuis le héros. **Mixage** : canaux Musique,
  Bruitages (compresseur + légère réverbération de sous-bois) et Ambiance, limiteur général.
  On entend : coups d'épée et de poing, saut et impact, dégainer/rengainer, pas (terre, bois du
  pont, eau), coups reçus, squelettes (os, râle, effondrement), coffre, lettre, feu, eau, vent.
- **Squelettes enterrés** : ils jaillissent de terre (gerbe de mottes, grondement) quand on
  approche, en laissant un trou.
- Le chemin part juste derrière le coffre, étroit et en dégradé sur 4 m.
- Arbres tordus au feuillage rouge retirés ; trous de la forêt comblés jusqu'aux limites.
- **Bruneval construit** (étape 9) d'après la **deuxième maquette, choisie par Tom** (il a
  préféré cette disposition plus régulière à la version « naturelle ») : `scripts/bruneval.gd`,
  positions « comme à l'écran » via `Chemin.bruneval(x, y)`. Clairière ovale entourée d'une
  ceinture de sapins (pas de palissade), chemin droit jusqu'à la place ovale de terre boueuse
  (flaques, feu de camp, banc du vieux Hugo), puits fabriqué. Maisons en arc, **façades
  éclairées tournées vers la caméra**, légèrement tournées vers la place (réglage
  « vers_place » par maison — Tom veut revoir les rotations ensuite) : **auberge** à étage au
  fond (lanterne, cheminée), **forge** en briques à gauche (cheminée, foyer rougeoyant,
  enclume, râtelier), **médecin** à droite, deux **abris** devant, **étal d'Osric** près de la
  place. Limite invisible le long de la clairière. « Bruneval » apparaît en y entrant.
- **Préférence de Tom : du naturel** (pas de cercle parfait, variété), mais pour Bruneval il a
  choisi la disposition plus régulière de la deuxième maquette : toujours montrer une maquette.
