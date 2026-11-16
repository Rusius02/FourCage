# FourCage server

Base locale du serveur Colyseus, séparée de l'application Flutter. Elle ne
contient volontairement aucune salle de jeu et n'implémente pas encore le
multijoueur.

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
variable d'environnement est définie). Vérifier son état sur
`http://localhost:2567/health`.

## Vérification

```powershell
npm test
npm run build
```

Le test démarre un vrai serveur temporaire et vérifie l'endpoint de santé. Le
port de test utilisé par Colyseus est `2568`.
