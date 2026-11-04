# ÉCHO VR — guide

Explore des épaves dans le noir. Le sonar et le gilet bHaptics X40 sont tes yeux.

## Lancer

- **PCVR** : connecte Virtual Desktop (ou SteamVR / Quest Link), allume le bHaptics Player Windows, puis lance `C:\Users\Olivier\Echo-VR-builds\pcvr\EchoVR.exe`.
- **Quest autonome** : installe **bHaptics Player** depuis le Meta Store, appaire le gilet, puis installe `C:\Users\Olivier\Echo-VR-builds\quest\EchoVR.apk` (mode développeur, `adb install -r EchoVR.apk`).

## Commandes

| Main gauche | | Main droite | |
|---|---|---|---|
| Stick | bouger | Stick | rotation (crans ou fluide) |
| Grip | courir (bruyant) | Gâchette | arme |
| Gâchette | faisceau sonar (visé à la main) | A | sonar autour de toi |
| X | recommencer / suivant | B | arme suivante |
| Y | menu | | |

La montre au poignet gauche affiche : vie, O₂, balises, arme et munitions, état du gilet.

## Objectif

Ramasse toutes les **balises** (+20 s d'oxygène chacune), puis atteins la **sortie**. Tu as 3 vies et 2 min 30 d'oxygène par épave.

## Armes

| Arme | Utilisation | Bruit |
|---|---|---|
| Couteau électrique | frappe physique, balance la main | faible |
| Fusil-harpon | tir précis à 25 m, 2 dégâts | moyen |
| Riveteuse | gerbe de 7 rivets à courte portée | fort |
| Découpeur plasma | maintenir la gâchette ; éclaire autour de toi | continu |
| Lance-torpille | projectile qui explose au contact | très fort |
| Grenade sonique | maintenir, lancer avec le geste, relâcher | énorme |
| Leurre | se lance comme la grenade, puis attire les monstres | énorme, mais loin de toi |

Chaque tir éclaire brièvement l'épave, mais le bruit attire les monstres. Il contourne les murs : derrière une cloison, il porte moins loin.

## Monstres

- **Rôdeur** : 3 PV, vitesse moyenne.
- **Traqueur** : 2 PV, rapide.
- **Colosse** : 7 PV, lent ; ses pas font trembler fort et ses coups enlèvent 2 vies.

Quand un monstre te voit à moins de 4 m, il **charge** et **rugit**. Les monstres proches le rejoignent.

## Ce que dit le gilet

Le menu « Lexique » fait jouer les 27 signaux un par un. Les principaux :

- **Murs** : la vague d'écho du sonar. Les murs proches répondent les premiers et le plus fort.
- **Balise** : double tapotement aux épaules. **Caisse** : triple tapotement en bas. **Trousse** : double impulsion au milieu du torse.
- **Monstre** : trois coups secs de son côté. Ses pas font trembler le bas du gilet, et son souffle se sent dans ton dos quand il est proche.
- **Ton cœur** bat plus vite quand le danger approche, et en permanence quand il te reste 1 vie.
- **Blessure** : impact violent du côté du coup, avec un voile rouge dans le casque.
- **Mur touché à la main** : la manette vibre et le gilet frémit de ce côté.

Le gilet suit ton **torse** et non ta tête : tourner seulement la tête ne fait pas tourner les vibrations.

## Réglages (menu)

Intensité du gilet (30 à 160 %), rotation (30°, 45° ou fluide), vignette de confort, position assis ou debout, recalibrage gauche/droite.

## Construire

- **Auto-test** (sans casque) :
  `Godot_v4.7.2-stable_win64_console.exe --headless --xr-mode off --fixed-fps 60 --path C:\Users\Olivier\Echo-VR -- --selftest`
- **PCVR** : `--headless --path C:\Users\Olivier\Echo-VR --export-release PCVR C:/Users/Olivier/Echo-VR-builds/pcvr/EchoVR.exe`
- **Quest** :
  1. Compile le plugin : `Echo-VR\android-plugin\gradlew.bat :plugin:assembleRelease`.
  2. Copie `plugin\build\outputs\aar\plugin-release.aar` vers `Echo-VR\addons\bhaptics_godot\bin\bhaptics_godot-release.aar`.
  3. Exporte le preset `Quest` (`--install-android-build-template`, puis `--export-debug Quest ...`).

## Tes modèles

Ils viennent de `F:\QUAKE RUST\assets\models` et sont copiés dans `Echo-VR\assets\models`. Si une arme pointe à l'envers dans la main, change son 3e nombre dans `WEAPON_MODELS` (en haut de `main.gd`) : 180 la retourne.
