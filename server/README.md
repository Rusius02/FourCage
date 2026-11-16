# FourCage server

Serveur Colyseus séparé de l'application Flutter. Il héberge la salle `match`
et exécute la simulation autoritaire : les clients ne transmettent que leurs
commandes de mouvement, jamais leur position ni leurs vies.

## Prérequis

- Node.js 22 ou supérieur
- npm

## Démarrer en local

Depuis ce dossier :

```powershell
npm install
npm start
```

Le serveur écoute sur le port `2567` par défaut (ou sur `PORT` si cette
variable d'environnement est définie). L'émulateur Android se connecte via
`ws://10.0.2.2:2567`. Un téléphone du même réseau utilise l'adresse IP locale
de l'ordinateur :

```powershell
flutter run --dart-define=COLYSEUS_SERVER_URL=ws://192.168.1.20:2567
```

Le port doit être autorisé dans le pare-feu. Les versions Release de
l'application refusent les URL `ws://` : configurez un endpoint `wss://` avec
TLS pour la production. La salle accepte quatre joueurs, démarre dès que la
salle est pleine ou après 10 secondes au maximum, puis utilise des bots pour
les places vides. Une déconnexion en cours de partie bénéficie de cinq
secondes pour se reconnecter avant le remplacement par un bot.

Cette base ne fournit pas encore d'authentification de comptes ni de limites
anti-abus globales. Elle ne doit pas être exposée directement à Internet en
production sans protections complémentaires. Vérifier son état sur
`http://localhost:2567/health`.

## Vérification

```powershell
npm test
npm run build
```

Les tests démarrent un vrai serveur temporaire, vérifient l'endpoint de santé,
le matchmaking et la validation des commandes. Le port de test Colyseus est
`2568`.
