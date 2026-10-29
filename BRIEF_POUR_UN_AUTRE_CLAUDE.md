# Brief du jeu de Tom — à lire avant de proposer une maquette

Ce document résume **l'état réel du jeu** (fin octobre 2026) pour un assistant qui n'a pas suivi
les échanges. Il sert surtout à préparer des **maquettes du village** cohérentes avec ce qui
existe déjà. Quand une maquette est validée, c'est Claude Code qui la construit dans Godot.

---

## 1. Avec qui tu parles

- **Tom** crée le jeu « par prompts ». Il débute et **ne code pas**.
- Parle-lui **en français**, simplement, sans jargon.
- Il aime qu'on lui **pose des questions avec des choix** avant de construire.
- Il veut **toujours voir une maquette** avant une construction.
- Il juge sur l'image : propose plusieurs variantes visuelles quand c'est utile.

## 2. Le jeu en bref

- **Genre** : action-RPG **dark fantasy**, solo, monde ouvert.
- **Moteur** : Godot 4.7.
- **Histoire** : un dieu a maudit le monde pour effacer l'humanité. Il fait **toujours nuit**, des
  monstres sont apparus (squelettes pour l'instant).
  - Phrase d'accroche : « Tant qu'il reste des survivants à protéger, il reste un dieu à abattre. »
- **Le héros** :
  - il est **amnésique** et se réveille assis près d'un feu de camp ;
  - tenue de paysan, cheveux longs noirs, **sans capuche** ;
  - il trouve une vieille épée dans un **coffre** près du feu.
- **Objectif final** (plus tard) : 5 zones, 5 boss, 5 reliques, la Grande Porte des Dieux, le dieu.
- **On travaille seulement sur la zone de départ** : clairière → chemin dans la forêt → hameau de
  **Bruneval**. La « Zone 1 » n'existe pas encore.

## 3. Direction artistique

- **Vraie 3D, low poly**, modèles du créateur **Quaternius** (gratuits, CC0).
- **Vue isométrique, caméra fixe, en perspective**, façon Diablo.
- **Nuit bleue lisible** : clair de lune bleuté, on voit bien le décor.
  - La seule touche chaude, c'est l'orange des feux, des torches et des fenêtres.
  - Le **rouge est réservé à la malédiction et au dieu**.
- **Couleurs sobres, jamais vives** : vert-gris éteint, bois brun-gris sombre, pierre gris froid,
  sol de terre brune sombre et lisse.
- **Tom n'aime pas** :
  - les fougères, les buissons, le trèfle, les dalles de pierre plates ;
  - les sols qui brillent par petits points ;
  - les arbres au feuillage rouge ;
  - la boussole ;
  - la capuche sur le héros.
- **Préférence de Tom** : du **naturel** (pas de symétrie parfaite, de la variété). Mais pour le
  village, il a finalement **choisi une disposition assez régulière** (voir la section 6).
- Police de l'interface : **Cinzel**.

## 4. ⚠️ Orientation des maquettes (très important)

La caméra du jeu regarde **en biais**, toujours dans la même direction. Dans tout le projet, on
raisonne **« comme à l'écran »**, pas en points cardinaux :

- **le haut de la maquette = le haut de l'écran en jeu** ;
- le joueur **avance vers le haut de l'écran** tout au long de la zone de départ ;
- **le chemin arrive dans Bruneval par le BAS de l'écran** (il vient de la forêt et du feu de camp) ;
- une future sortie vers la Zone 1 serait donc logiquement **en haut** (à l'opposé de l'arrivée) ;
- dans le jeu, on voit le **devant** des maisons tourné vers le bas de l'écran, c'est-à-dire vers
  la caméra. C'est pour ça que Tom a choisi des **façades éclairées tournées vers la caméra**.

Il n'y a **pas de nord** dans le jeu : évite « Nord/Sud », dis « haut/bas de l'écran ».

## 5. La zone de départ aujourd'hui (du bas vers le haut de l'écran)

1. **La clairière du feu de camp** :
   - le héros est assis sur un rondin près du feu ;
   - un coffre contient l'épée ;
   - la forêt tout autour (pins, arbres morts).
2. **Le chemin dans la forêt** (environ 150 m), un sentier de terre battue presque droit vers le
   haut, bordé de lanternes. Une **forêt serrée de chaque côté**, avec des limites invisibles : le
   parcours est **linéaire**. Dans l'ordre :
   - une **cabane à moitié effondrée** à gauche ;
   - un **ruisseau** qui traverse l'écran de gauche à droite, avec un **pont de bois** fait main
     (on peut aussi marcher dans l'eau) ;
   - **3 squelettes** qui **sortent de terre** quand on approche (premier combat) ;
   - un **autel** à la lueur rouge à droite ;
   - une **charrette renversée** à gauche (simple décor) ;
   - la **cabane de l'écrivain** à droite, juste avant le village : une table avec une **lettre**
     sous un faisceau de lumière dorée. E pour la lire. Maren y écrit à **Aldric** : un dieu a
     maudit le monde, les morts se relèvent, il doit partir vite chercher **sa fille**.
3. **Bruneval** (voir ci-dessous) : deux **torches** à l'entrée, en bas.

En haut de l'écran pendant le chemin : un **repère discret** (trait orné et chevron) qui indique la
direction, **sans nom**. Le nom « Bruneval » apparaît en grand quand on entre dans le hameau.

## 6. Bruneval tel qu'il est construit (validé par Tom)

Tom a validé cette disposition. Il veut **retravailler le village**, donc tu peux proposer des
changements, mais pars de cette base et signale clairement ce que tu modifies.

**Forme générale**

- Une **clairière ovale** (environ 54 m de large sur 42 m de haut), entourée d'une **ceinture de
  sapins serrés**. **Pas de palissade** : Tom l'a refusée et préfère les arbres.
- Le **chemin arrive par le bas**, passe entre les deux torches et va **tout droit** jusqu'à la
  place.
- Au centre, une **place ovale de terre boueuse** avec des flaques, et le **feu de camp** au milieu.

**Plan actuel**, en mètres, comme à l'écran : x vers la droite, y vers le haut, (0, 0) = le feu.

| Élément | Position (x, y) | Détails |
| --- | --- | --- |
| Feu de camp | (0, 0) | Particules, lit de braises ; futur point de sauvegarde |
| Banc du vieux Hugo | (-2.8, -2.9) | Tourné vers le feu |
| Puits | (5.6, 3.3) | Margelle de pierre, poteaux, seau |
| Étal d'Osric | (-7.4, -5.7) | Étal du pack, caisses de pommes et de carottes |
| **Auberge** | (0, 15.2) | Au fond. 10 m de façade, **2 étages**, lanterne à la porte, cheminée |
| **Forge** | (-19.3, 3.1) | À gauche. Briques, 8 m de façade, cheminée, foyer rougeoyant, enclume, râtelier d'armes |
| **Médecin** | (20.2, 3.8) | À droite. 8 m de façade |
| **Abri** | (-17.1, -8.7) | Devant à gauche. 6 m de façade |
| **Abri de l'est** | (17.1, -9.1) | Devant à droite. 6 m de façade |
| Entrée (2 torches) | (0, -20.5) | Le chemin arrive d'en bas |

- Les maisons sont **en arc autour de la place**. Leurs **façades** (avec la porte et les fenêtres
  éclairées) **regardent la caméra**, avec une légère rotation vers la place : la forge et le
  médecin sont un peu tournés, l'auberge est droite. **Tom veut revoir ces rotations.**
- **On ne peut pas encore entrer dans les maisons.** C'est prévu ensuite : entrer fait passer à une
  pièce à part, comme dans Pokémon.

**Les survivants** (déjà dans le jeu, chacun a sa place et son activité)

| Nom | Où | Tenue / activité |
| --- | --- | --- |
| **Bran** | À l'entrée, à côté des torches | Rôdeur à capuche, une torche à la main, il monte la garde |
| **Hugo** (le vieux) | Assis sur le banc près du feu | Paysan, barbe et cheveux gris ; il raconte des histoires |
| **Élise** | Va et vient entre le puits et l'abri de l'est | Paysanne en chignons, elle porte de l'eau |
| **Osric** | Derrière son étal | Marchand, il range ses affaires de temps en temps |
| **Maren** | Devant l'auberge, bras croisés | Rôdeuse à capuche, mystérieuse ; c'est elle qui a écrit la lettre à Aldric |

- **Aldric** n'est **pas** le héros : c'est un autre homme, parti chercher sa fille, jamais revenu.
- Avec E près d'un survivant, une **bulle de dialogue** s'ouvre en bas de l'écran (texte lettre par
  lettre).

## 7. Ce que la maquette jointe de l'autre Claude a de différent

Elle est belle, mais elle s'écarte de ce qui existe sur ces points. Si Tom veut les garder, c'est
un choix à confirmer avec lui :

- **Arrivée par le haut (« nord »)** : dans le jeu, le chemin arrive par le **bas** de l'écran.
- **Palissade** : Tom l'a **refusée**, il préfère la forêt autour.
- **Sept maisons en cercle** : il y en a **cinq** aujourd'hui (auberge, forge, médecin, deux
  abris). En ajouter est possible.
- **Survivants assis autour du feu, encapuchonnés** : aujourd'hui, seul Hugo est au feu ; les
  autres ont chacun leur place (voir le tableau). Seuls Bran et Maren portent une capuche.
- **Maisons tournées vers le centre** : aujourd'hui, les façades regardent la caméra, pour qu'on
  voie les fenêtres éclairées. Tom veut revoir les rotations, c'est donc un bon sujet de maquette.
- **« Sentier de la montagne »** : c'est un chemin dans la forêt, avec ruisseau, pont, cabane et
  autel. Il n'y a pas de montagne pour l'instant.
- **Sortie vers la Zone 1** : bonne idée pour plus tard. Elle serait en **haut** de l'écran,
  derrière l'auberge, à l'opposé de l'arrivée.

## 8. Ce qu'on peut construire (pour rester réaliste)

Avec le **Medieval Village MegaKit** de Quaternius :

- **Murs par modules de 2 m** : plâtre, colombages, briques. Il existe des portes, des fenêtres
  larges ou fines, des volets, des cheminées, des balcons, des escaliers extérieurs et des
  avancées d'étage.
- **Toits complets à deux pentes**, en 4×4, 4×6, 4×8, 6×6, 6×8, 6×10 m (et plus grand dans le
  pack : 6×12, 6×14, 8×8 à 8×14).
- Un ou deux étages.

Avec le **Fantasy Props MegaKit** : enclume, étals, tonneaux, caisses de fruits et légumes, seaux,
bancs, chaises, tables, bougies, livres, râtelier d'armes, bannières, lanternes, torches.

Il n'y a **pas de puits** ni de **pont** tout faits : on les fabrique à la main (c'est déjà fait).

## 9. Bonnes pratiques pour une maquette qui marche

- Vue de dessus « comme à l'écran », **arrivée du chemin en bas**, avec une **légende** et des
  **numéros**.
- Une **deuxième vue sous l'angle du jeu** (en biais, de nuit, fenêtres éclairées) aide beaucoup
  Tom à décider.
- Donne des tailles en mètres. Les maisons font de 6 à 10 m de façade, et le hameau tient dans
  environ 54 × 42 m.
- Reste dans la palette : nuit bleue, orange pour les lumières, rouge seulement pour la malédiction.
- Propose **2 ou 3 variantes** si Tom hésite, puis demande-lui laquelle il préfère.

## 10. Ce que Tom veut pour la suite du village (décisions récentes)

- Le village sera **retravaillé** à partir de ta maquette.
- **Boutiques** : on pourra **acheter des armes et des armures** chez le forgeron, et **des
  potions** chez le médecin. D'autres commerces sont possibles.
- **Les habitants** seront des personnages « lambda », sauf un : **le chef du village**. On
  **entre dans sa maison** (une pièce à part), et une **icône de quête** flotte au-dessus de lui.
  Prévois donc sa maison sur le plan, bien visible.
- Tom veut de **vrais petits bâtiments caractéristiques** (forge avec son atelier ouvert,
  boutique du médecin…), pris dans des packs gratuits, plutôt que des maisons toutes pareilles.
  Le forgeron et le médecin doivent se reconnaître au premier coup d'œil.
