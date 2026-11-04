# ÉCHO VR

**Un jeu d'horreur en réalité virtuelle où l'on « voit » avec la peau.**

Tu explores des épaves englouties plongées dans le noir total. Ton seul moyen de te repérer : un sonar et un gilet haptique **bHaptics TactSuit X40**, dont les 40 moteurs dessinent autour de ton torse les murs, les balises, les monstres qui rôdent et les battements de ton propre cœur.

- **PCVR** : Windows + OpenXR (Virtual Desktop, SteamVR, Quest Link).
- **Meta Quest autonome** : APK Android natif, le gilet passe par l'app bHaptics Player du casque.
- Moteur : **Godot 4.7.2**, tout en GDScript, et un petit plugin Android en Java pour le gilet.

---

## Sommaire

1. [Le principe](#le-principe)
2. [Gameplay](#gameplay)
3. [Commandes](#commandes)
4. [Armes](#armes)
5. [Monstres](#monstres)
6. [Le langage du gilet](#le-langage-du-gilet)
7. [Réglages et confort](#réglages-et-confort)
8. [Installer et jouer](#installer-et-jouer)
9. [Construire depuis les sources](#construire-depuis-les-sources)
10. [Architecture du code](#architecture-du-code)
11. [Le pont haptique en détail](#le-pont-haptique-en-détail)
12. [Tests automatiques](#tests-automatiques)
13. [Limites connues](#limites-connues)
14. [Licences et crédits](#licences-et-crédits)

---

## Le principe

L'écran est presque noir. Quand tu lances le **sonar**, une onde part de toi à 7 m/s. Chaque surface qu'elle touche te renvoie un écho :

- **dans le gilet**, à l'angle exact où se trouve l'obstacle. Plus il est proche, plus l'écho est fort et rapide ; derrière toi, il vibre dans le dos ;
- **dans le casque**, sous la forme d'un nuage de points bleus qui dessine les parois puis s'efface.

Le sonar fait du bruit, et le bruit attire les monstres. Toute la tension du jeu vient de cet arbitrage permanent : **voir ou rester discret**.

Le gilet suit l'orientation de ton **torse**, pas de ta tête. Si tu tournes seulement la tête pour regarder, les vibrations restent à leur place, comme un vrai son dans l'espace.

## Gameplay

| Élément | Rôle |
|---|---|
| **Balises** | À ramasser toutes pour ouvrir la sortie. Chacune rend +20 s d'oxygène. |
| **Sortie** | Fermée tant qu'il reste des balises ; son écho change quand elle s'ouvre. |
| **Oxygène** | 2 min 30 par épave. Sous 30 s : le gilet te serre les épaules et une alarme sonne. |
| **Vie** | 3 points. Un coup de griffe en enlève 1 (2 pour un colosse) et te projette en arrière. |
| **Trousses de soin** | +1 vie. |
| **Caisses de munitions** | Rechargent toutes les armes. |

**Modes de jeu**

- **Campagne** : 5 épaves. Les 3 premières sont faites à la main et servent de tutoriel progressif ; les 2 dernières sont générées avec une graine fixe. Ton meilleur temps total est enregistré.
- **Plongée infinie** : une nouvelle épave procédurale à chaque niveau, plus grande, avec plus de balises et des monstres plus durs. Ton record de profondeur est enregistré.

Les épaves procédurales sont des labyrinthes avec boucles et salles. Les balises sont placées en priorité dans les culs-de-sac, et les monstres loin du départ et espacés entre eux. Un test vérifie sur 60 graines que tout reste accessible.

## Commandes

Manettes Meta Quest (Touch), ou toute manette OpenXR équivalente.

| Main gauche | | Main droite | |
|---|---|---|---|
| **Stick** | se déplacer | **Stick** | tourner (crans 30° / 45° ou fluide) |
| **Grip** | courir (bruyant) | **Gâchette** | utiliser l'arme |
| **Gâchette** | faisceau sonar dirigé, visé avec la main | **A** | sonar à 360° |
| **X** | recommencer / épave suivante | **B** | arme suivante |
| **Y** | menu | | |

- **Montre au poignet gauche** : vie, O₂, balises, arme et munitions, état du gilet.
- **Menu 3D** : il flotte devant toi ; tu vises avec un laser depuis la main droite et tu valides avec la gâchette.
- **Mouvement physique** : tu peux marcher pour de vrai, mais les murs te repoussent. Si ta tête entre dans une cloison, le gilet cogne de ce côté.

## Armes

Toutes les armes se tiennent dans la main droite. Les tirs suivent l'orientation réelle de la manette, inclinaison comprise.

| Arme | Utilisation | Dégâts | Bruit |
|---|---|---|---|
| **Couteau électrique** | geste de frappe réel (vitesse de la main > 2,2 m/s) | 1 | faible |
| **Fusil-harpon** | tir précis jusqu'à 25 m, recharge 1 s | 2 | moyen |
| **Riveteuse** | gerbe de 7 rivets, 9 m, ±12° | 0,7 par rivet | fort |
| **Découpeur plasma** | maintenir la gâchette ; éclaire autour de toi | 1,6 par seconde | continu |
| **Lance-torpille** | projectile explosif (rayon 3 m) | 4 | très fort |
| **Grenade sonique** | maintenir la gâchette, faire le geste du lancer, relâcher ; rebonds, mèche 1,6 s | 4 (zone 3,5 m) + étourdit | énorme |
| **Leurre** | se lance comme la grenade, puis émet 3 impulsions qui attirent les monstres | – | énorme, loin de toi |

Chaque tir **éclaire brièvement** l'épave : il révèle, mais il trahit. Le bruit se propage en **contournant les murs** (recherche de chemin), donc une cloison étouffe un tir.

## Monstres

| Type | PV | Vitesse | Particularité |
|---|---|---|---|
| **Rôdeur** | 3 | moyenne | le monstre de base |
| **Traqueur** | 2 | rapide | pas légers et rapides ; apparaît dès la profondeur 3 |
| **Colosse** | 7 | lente | ses pas font trembler fort ; ses coups enlèvent 2 vies ; apparaît dès la profondeur 5 |

Comportement :

1. **Errance** : il va de case en case au hasard.
2. **Chasse** : il entend un bruit et se dirige vers sa source.
3. **Charge** : il te voit à moins de 4 m, fonce sur toi et **rugit**. Les monstres à moins de 10 m rejoignent la chasse.
4. **Attaque** : un coup toutes les 1,2 s, puis il reprend son élan ; c'est ta chance de fuir.

Le sonar les révèle un instant sous la forme d'une **silhouette rouge**.

## Le langage du gilet

Le menu **Lexique** fait jouer chacun des **27 signaux** deux fois, avec son nom affiché. Les principaux :

| Signal | Ressenti |
|---|---|
| Écho de mur | impulsion au milieu du torse, à l'angle du mur ; plus forte s'il est proche |
| Balise | double tapotement aux épaules |
| Caisse de munitions | triple tapotement en bas du gilet |
| Trousse de soin | double impulsion au milieu |
| Sortie ouverte | vague qui monte du ventre vers les épaules |
| Monstre repéré | trois coups secs de son côté |
| Pas d'un monstre | tremblement du bas du gilet, de son côté |
| Souffle d'un monstre | respiration lente, quand il est à moins de 5 m |
| Charge | balayage violent du côté du monstre |
| Rugissement | grondement vibrant venant de la meute |
| Ton cœur | « lub-dub » à gauche de la poitrine, d'autant plus rapide que le danger approche |
| Blessure | impact du côté du coup, plus un voile rouge dans le casque |
| Tes pas | petits contacts alternés gauche/droite sur le ventre |
| Recul d'arme | choc en haut à droite (côté de l'arme) |
| Arme rechargée | petit clic |
| Main contre un mur | la manette vibre, le gilet frémit de ce côté |
| Oxygène bas | compression autour des épaules |

Au premier lancement, une **calibration** (deux vibrations à répondre gauche ou droite) corrige automatiquement une éventuelle inversion gauche/droite, devant comme dans le dos.

## Réglages et confort

- Intensité du gilet : 30 à 160 %.
- Rotation : crans de 30°, crans de 45° ou fluide.
- Vignette de confort pendant les déplacements.
- Position assis ou debout : la vue est relevée de 45 cm en position assise.
- Fréquence d'affichage : la plus haute disponible sur PC, plafonnée à 90 Hz sur Quest.
- Rendu fovéal dynamique : la périphérie est rendue avec moins de détail.

Les réglages et les records sont stockés dans `user://echo.cfg`.

## Installer et jouer

### PCVR (Windows)

1. Télécharge `EchoVR-PCVR-win64.zip` depuis les [Releases](../../releases) et décompresse-le.
2. Lance le **bHaptics Player** Windows et allume le gilet.
3. Connecte ton casque (Virtual Desktop, SteamVR ou Quest Link) en tant que runtime OpenXR.
4. Lance `EchoVR.exe`.

### Meta Quest autonome

1. Sur le casque, installe **bHaptics Player** depuis le Meta Horizon Store, accepte les permissions et appaire le gilet ([guide bHaptics](https://support.bhaptics.com/support/solutions/articles/150000209817-install-the-bhaptics-player-for-meta-quest)).
2. Active le mode développeur du Quest.
3. Télécharge `EchoVR.apk` depuis les [Releases](../../releases) et installe-le :
   ```bash
   adb install -r EchoVR.apk
   ```
4. Lance Écho VR depuis « Sources inconnues ».

Installe bHaptics Player **avant** de lancer le jeu. Si tu l'installes pendant que le jeu tourne, redémarre le jeu.

## Construire depuis les sources

### Prérequis

- [Godot 4.7.2](https://godotengine.org/download) et ses **export templates**.
- Pour Quest : Android SDK (build-tools 35+, plateforme 35), JDK 17, et les chemins configurés dans l'éditeur Godot (*Editor Settings → Export → Android*).

### Dépendances tierces à placer soi-même (non versionnées)

| Fichier | Où le mettre | Source |
|---|---|---|
| Godot OpenXR Vendors 5.1 | `addons/godotopenxrvendors/` | [GodotVR/godot_openxr_vendors](https://github.com/GodotVR/godot_openxr_vendors/releases), `godotopenxrvendorsaddon.zip` |
| `bhaptics_manager.aar` | `android-plugin/plugin/libs/` **et** `addons/bhaptics_godot/bin/` | [bhaptics/tact-android](https://github.com/bhaptics/tact-android/tree/master/libs) |

### Lancer l'auto-test (sans casque)

```bash
godot --headless --xr-mode off --fixed-fps 60 --path . -- --selftest
```

### Exporter PCVR

```bash
godot --headless --path . --export-release PCVR build/pcvr/EchoVR.exe
```

### Exporter pour Quest

1. **Compiler le plugin Android** :
   ```bash
   cd android-plugin
   gradlew assembleRelease
   ```
   puis copier `plugin/build/outputs/aar/plugin-release.aar` vers `addons/bhaptics_godot/bin/bhaptics_godot-release.aar`.
2. **Installer le modèle de build Android** : *Project → Install Android Build Template* dans l'éditeur, ou décompresser `android_source.zip` des export templates dans `android/build/`.
3. **Exporter** :
   ```bash
   godot --headless --path . --export-debug Quest build/quest/EchoVR.apk
   ```

Le preset `Quest` active le build Gradle, le mode XR OpenXR, le plugin Meta, arm64 uniquement, et la compression de textures ETC2/ASTC.

## Architecture du code

```
main.gd                 jeu complet : niveaux, sonar, IA, armes, physique des lancers,
                        rendu haptique, menus VR, calibration, lexique, auto-test
vest.gd                 tampon 40 moteurs (4×5 devant + 4×5 dos) → bHaptics Player
mazegen.gd              générateur d'épaves (backtracker + boucles + salles + placement)
sfx.gd                  tous les sons synthétisés à la volée : relais, servos, grondements
assets/models/          modèles GLB : armes, monstres, caisses, trousses
addons/bhaptics_godot/  export plugin : ajoute les AAR et le <queries> du manifeste
android-plugin/         plugin Android Godot v2 (Java) autour du SDK bHaptics
export_presets.cfg      presets « PCVR » et « Quest »
GUIDE.md                aide-mémoire du joueur
```

### Choix techniques notables

- **Monde en grille 2D, rendu en 3D.** Collisions, sonar, ouïe et IA travaillent sur la grille ASCII du niveau. Les lancers et les torpilles ont une vraie physique 3D (gravité, rebonds).
- **Sonar en DDA.** Chaque rayon traverse la grille case par case (algorithme d'Amanatides-Woo). C'est exact et environ 20 fois moins coûteux qu'une marche à pas fixe, ce qui compte sur Quest.
- **Nuage de points en MultiMesh.** Une onde sonar produit un seul nœud par vague, et ses points sont révélés au fil de l'onde.
- **Effets haptiques déclaratifs.** Chaque événement crée un effet (type, durée, angle ou point du monde, intensité). Toutes les 50 ms, ces effets sont « dessinés » dans le tampon du gilet comme on dessine une image, puis envoyés en une seule trame.
- **Panoramique haptique circulaire.** Les 8 colonnes du gilet sont réparties à 45° d'intervalle autour du torse. Un point à un angle donné active les colonnes voisines, pondérées par leur distance angulaire.
- **Torse estimé.** Le lacet du torse suit celui de la tête avec une zone morte de 35°, et se recale plus vite quand tu marches.
- **Vitesse de la main en repère local.** Elle ignore la locomotion au stick, les rotations et les reculs, si bien que seul un vrai geste compte pour le couteau et les lancers.
- **Pause cohérente.** Au retour du menu, tous les minutages en cours sont décalés de la durée de la pause : grenades, torpilles, échos et leurres reprennent là où ils en étaient.
- **Modèles mis à l'échelle automatiquement.** La boîte englobante de chaque GLB est mesurée, puis le modèle est centré, orienté sur l'axe -Z et mis à l'échelle. Le résultat est mis en cache et dupliqué à chaque usage.

## Le pont haptique en détail

### PC

`vest.gd` ouvre un websocket vers le bHaptics Player Windows (`ws://127.0.0.1:15881/v2/feedbacks`) et envoie des trames `DotPoints` (`VestFront` / `VestBack`, index = ligne × 4 + colonne). Aucune clé d'API n'est nécessaire. Une trame vide n'est envoyée qu'une seule fois.

### Quest

`android-plugin` est un plugin Godot Android v2 (`org.godotengine.plugin.v2.BhapticsGodot`). Il enveloppe `SdkRequestHandler` du SDK officiel [tact-android](https://github.com/bhaptics/tact-android), qui parle en AIDL à l'app **bHaptics Player for Quest**. Le jeu n'a donc besoin d'aucune permission Bluetooth.

| Méthode exposée | Rôle |
|---|---|
| `init(appId, apiKey)` | se connecte à bHaptics Player ; renvoie `false` s'il n'est pas installé |
| `is_vest_connected()` | indique si le gilet est appairé et allumé |
| `play_motors(0, durée, int[32])` | pilote le TactSuit vu en 32 moteurs (4×4 devant, 4×4 dos) |
| `stop_all()` | coupe tout |

Côté jeu, les 5 lignes logiques sont ramenées à 4 : la ligne du milieu se répartit sur ses deux voisines. L'export plugin ajoute `<queries><package android:name="com.bhaptics.player"/></queries>` au manifeste, ce qui est obligatoire depuis Android 11.

## Tests automatiques

`-- --selftest` lance le jeu sans casque avec des entrées simulées, puis exécute **50 vérifications** :

- **Générateur** : 60 épaves vérifiées ; départ, balises, munitions, trousses et sortie toujours reliés.
- **Campagne** : chaque épave est chargée, explorée au sonar et au faisceau.
- **Monstres** : charge à vue, blessure, mort après 3 coups, cœur et tremblements, rugissement qui alerte la meute, ouïe par chemin.
- **Armes** : harpon (dégâts et recharge), couteau (une rotation ne compte pas comme une frappe), riveteuse, plasma, torpille (explose devant la paroi et non dedans), grenade, leurre, caisses, chargement des 7 modèles.
- **Progression** : oxygène, mort par asphyxie, balises, sortie, enchaînement des épaves, records.
- **Menu et VR** : pause et reprise sans dérive des minutages, pas de « Reprendre » après une mort, mur traversé physiquement puis repoussé, torse et zone morte, menu, calibration, lexique complet.

Le code a aussi fait l'objet d'une revue indépendante. Les 12 points relevés ont été corrigés, puis couverts par des tests.

## Limites connues

- Le torse est **estimé** à partir de la tête : il n'y a pas de traqueur de hanche.
- Pas encore d'icône de projet : l'export Android le signale, mais l'APK se construit quand même.
- L'APK publié est un **build debug**, signé avec la clé de debug.
- L'équilibrage (oxygène, vitesses, dégâts) n'a pas encore été affiné par de longues sessions en casque.

## Licences et crédits

- **Code du projet** : licence MIT, voir [LICENSE](LICENSE).
- **Modèles 3D** (`assets/models/`) : fournis par l'auteur.
- **bHaptics SDK** : soumis au [bHaptics SDK agreement](https://bhaptics.gitbook.io/license-sdk/) ; à télécharger depuis le dépôt officiel.
- **Godot Engine** (MIT) et **Godot OpenXR Vendors** (MIT ; les chargeurs OpenXR Meta et Pico suivent la licence de leurs éditeurs).
- Tous les sons sont **synthétisés par le code**, il n'y a aucun fichier audio.

Conçu et joué par Olivier, développé avec l'aide de Claude (Anthropic).
