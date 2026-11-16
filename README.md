# FourCage

FourCage est un jeu de football arcade en vue de dessus, jouable hors ligne
contre trois bots. Quatre joueurs défendent chacun une cage et disposent de
trois vies. Marquez dans les cages adverses, éliminez les bots et protégez la
vôtre. L'application Android se joue en paysage.

## Modes de jeu

- **Solo** : match contre trois bots, jouable hors ligne.
- **Multijoueur** : le choix apparaît dans le menu, mais le jeu en ligne n'est
  pas encore disponible. Le menu l'indique sans démarrer un faux match.

## Jouer

- **Joystick gauche** : déplacer votre joueur.
- **TIRER** : envoyer le ballon vers la cage adverse ouverte la plus proche
  (vous devez être à portée du ballon).
- Chaque but encaissé retire une vie. Une cage éliminée est fermée.

Lancez les tests avec `flutter test` et l'application avec `flutter run`.

## Organisation du code

Le code est organisé par fonctionnalité :

- `lib/features/match/domain/` contient le moteur de match et les règles, sans
  dépendance à Flutter.
- `lib/features/match/application/` expose les actions du match à l'interface
  via un contrôleur observable.
- `lib/features/match/presentation/` contient l'écran de jeu et le rendu du
  terrain.
- `lib/features/home/presentation/` contient le menu et la sélection du mode.
- `lib/app/` regroupe le thème et la palette partagée.

## Build Android

Pour générer un APK de test :

```powershell
flutter build apk --debug
```

Google Play distribue de préférence un Android App Bundle (`.aab`). Avant le
premier build de publication, créez **et sauvegardez en lieu sûr** votre clé
de téléversement (ne la partagez jamais et ne la commitez pas) :

```powershell
keytool -genkey -v -keystore "$HOME\fourcage-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias fourcage-upload
Copy-Item android\key.properties.example android\key.properties
```

Dans `android\key.properties`, remplacez les valeurs d'exemple par les mots de
passe choisis et le chemin complet vers votre fichier `.jks`, au format
`C:/Users/votre-nom/fourcage-upload.jks`. Ce fichier et les clés sont exclus
du contrôle de version. **Sans ce fichier, le bundle produit est non signé et
ne peut pas être envoyé sur Google Play.** Ne partagez jamais cette clé ;
conservez une copie de sauvegarde sécurisée.

Puis construisez le bundle :

```powershell
flutter build appbundle --release
```

Le bundle est généré dans
`build\app\outputs\bundle\release\app-release.aab`. Sans
`android\key.properties`, le build Release n'utilise volontairement **pas** la
clé de débogage. Configurez votre clé avant d'envoyer le bundle sur Play
Console. L'icône 512 × 512 pour la fiche Play se trouve dans
`assets\store\fourcage-icon-512.png`. Incrémentez `version` dans `pubspec.yaml`
pour chaque nouvelle version publiée.

Le mode en ligne n'est pas implémenté dans cette première version : les trois
adversaires sont des bots exécutés sur l'appareil.
