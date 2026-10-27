# Processus : la zone de départ

Ce fichier décrit seulement le **début du jeu** : du feu de camp jusqu'au hameau de Bruneval.
Le contexte complet du jeu est dans `CONTEXTE.md`.

## Règles

- **Une étape à la fois.** Ne commence pas l'étape suivante avant que Tom ait validé la précédente.
- Après chaque étape : explique simplement ce que tu as fait, dis à Tom comment tester, et
  enregistre la version avec git.
- Formes simples d'abord (cubes, cônes, capsules) pour valider l'idée, puis vrais modèles 3D.
- Respecte la direction artistique de `CONTEXTE.md` à chaque étape.
- Terrain **plat** pour l'instant. Vue **isométrique, caméra fixe**.

## Ce que le joueur vit

1. Le jeu commence de nuit, sans intro : le personnage est assis sur un tronc près d'un feu de
   camp, dans une clairière au milieu d'une forêt de pins et d'arbres morts.
2. Il se lève et suit un chemin dans la forêt (environ 1 minute), en passant devant une ruine, un
   ruisseau, un autel maudit et une charrette renversée où il trouve une vieille épée.
3. Il arrive au hameau de Bruneval, parle aux survivants et visite les maisons.

## Les étapes

### Étape 1 : le projet

- Créer le projet dans la dernière version stable de Godot 4, avec un dossier clair.
- Initialiser git (et le relier au compte GitHub de Tom s'il le souhaite).
- **Tom valide quand** le projet s'ouvre et se lance sur un écran vide, sans erreur.

### Étape 2 : la clairière du feu de camp

- Un sol plat de nuit, une clairière de taille moyenne entourée de pins et d'arbres morts, avec un
  vieil arbre mort au bord.
- Un feu de camp (pierres, bûches, flammes) avec une lumière orange qui vacille et des braises.
- Un tronc à côté du feu pour s'asseoir. Rien d'autre autour du feu.
- Nuit bleue lisible : clair de lune bleu, on voit bien le décor.
- Caméra isométrique fixe.
- **Tom valide quand** l'ambiance lui plaît.

### Étape 3 : le personnage

- Un personnage temporaire (une capsule suffit), vu par la caméra isométrique fixe qui le suit.
- Déplacements avec ZQSD (clavier AZERTY) **ou** en cliquant au sol avec la souris. Maj pour
  courir, Espace pour une **roulade**.
- Au lancement, le personnage est **assis sur le tronc, face au feu**. Il se lève dès que le
  joueur bouge.
- Touche E près du tronc : s'asseoir ou se relever (message « E : s'asseoir » affiché).
- **Tom valide quand** il se déplace facilement et que la caméra est agréable.

### Étape 4 : l'effet 3D pixel et la palette

- Rendu en basse résolution, agrandi sans lissage. **Effet léger** (pixels de taille 2 environ).
- Palette commune appliquée à tous les modèles (voir `CONTEXTE.md`).
- **Tom valide quand** le rendu ressemble à ses références.

### Étape 5 : les vrais modèles de la clairière

- Remplacer les formes simples par les modèles Quaternius : pins, arbres morts, rochers, herbes,
  feu, tronc.
- **Demander à Tom avant de télécharger un pack.**
- **Tom valide quand** la clairière est cohérente et belle.

### Étape 6 : le vrai personnage

- Remplacer la capsule par un voyageur encapuchonné animé (repos, marche, course, roulade,
  s'asseoir).
- **Tom valide quand** le personnage lui plaît et que les animations sont fluides.

### Étape 7 : le feu de camp qui sauvegarde

- S'asseoir au feu de camp sauvegarde la partie (pour commencer : la position du joueur).
- Relancer le jeu reprend au dernier feu de camp.
- **Tom valide quand** la sauvegarde fonctionne.

### Étape 8 : le chemin dans la forêt

- Un sentier de terre plat qui serpente de la clairière jusqu'au hameau (environ 1 minute de
  marche), bordé de lanternes.
- Le long du chemin : une ruine couverte de mousse, un ruisseau à l'eau sombre et calme avec un
  petit pont de bois, un autel abandonné avec une lueur rouge.
- Une charrette renversée : touche E pour la fouiller, on trouve une **vieille épée**.
- Une petite boussole en haut de l'écran indique la direction du hameau.
- **Tom valide quand** le trajet est agréable et qu'on ne se perd pas.

### Étape 9 : le hameau de Bruneval

- 4 à 6 abris de fortune rafistolés tournés vers une place, une palissade rafistolée avec une
  entrée et des torches là où arrive le chemin, le puits, l'étal d'Osric sous son auvent, des
  flaques.
- Un feu de camp sur la place, qui sauvegarde aussi.
- **Tom valide quand** le hameau lui plaît.

### Étape 10 : les survivants

- Placer les survivants et leur donner une petite activité : Bran garde l'entrée avec une torche,
  Élise va et vient entre le puits et une maison, le vieux Hugo est assis au feu, Osric range son
  étal, Maren (mystérieuse) à un endroit choisi par Tom.
- Touche E près d'un personnage : une bulle de dialogue en bas de l'écran (nom, puis le texte
  qui s'écrit lettre par lettre ; E pour continuer). Tom choisit les répliques.
- **Tom valide quand** les survivants et les dialogues fonctionnent.

### Étape 11 : les intérieurs

- Entrer dans une maison fait passer à un nouvel écran, une pièce à part (comme dans Pokémon),
  puis ressortir ramène devant la porte.
- Commencer par l'auberge, puis le forgeron et le médecin (Tom choisit leurs noms).
- **Tom valide quand** on entre et sort des maisons sans souci.

### Étape 12 : les sons

- Le feu qui crépite (plus fort quand on est près), la forêt la nuit (vent, chouette, insectes),
  une musique douce et un peu triste.
- **Demander à Tom avant de télécharger des sons.**
- **Tom valide quand** l'ambiance sonore lui plaît.

## Plus tard (pas maintenant)

Ne pas commencer sans l'accord de Tom : le choix de la classe, le combat et le premier ennemi, la
première quête, l'expérience et l'arbre de compétences, la boutique du marchand, la première
nouvelle tenue, la barre de vie, puis la route vers la Zone 1.
