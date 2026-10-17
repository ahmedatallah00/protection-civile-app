# 🚒 Protection Civile Tunisie (ONPC) - Plateforme Intelligente

Système numérique intégré pour l'**Office National de la Protection Civile (ONPC)** de Tunisie, facilitant les interventions de secours, la gestion en temps réel des urgences, l'engagement des bénévoles et la communication avec les citoyens.

---

## 📌 Architecture du Projet

Le projet est structuré sous forme de monorepo contenant les 3 composants essentiels :

```text
protection_civile_app/
├── backend/            # Serveur API REST (Node.js, Express, MongoDB, Socket.io)
├── dashboard_admin/    # Tableau de bord Web d'administration et de dispatching (HTML5, CSS3, JS, Leaflet)
├── mobile_app/         # Application mobile citoyenne & bénévole (Flutter / Dart)
├── .gitignore          # Règles d'exclusion Git pour un dépôt propre et sécurisé
└── README.md           # Documentation générale
```

---

## 🚀 Fonctionnalités Clés

### 📱 1. Application Mobile Citoyenne & Bénévole (`mobile_app/`)
* **Urgence Absolue & SOS Instantané** : Déclenchement d'un appel au secours en un clic avec envoi automatique des coordonnées GPS précises et de la fiche médicale.
* **Bouton Direct Vidéo (Live Streaming)** : Transmission vidéo en direct depuis la caméra du smartphone vers le centre de commandement lors d'une catastrophe.
* **Signalement Multimédia Enrichi** : Déclaration d'incidents (incendies, accidents de la route, inondations, effondrements) avec photos, vidéos et mémos vocaux enregistrés.
* **Statut de Bénévole (متطوع)** : Inscription en tant que bénévole de la Protection Civile avec badge interactif affiché sur le profil.
* **Historique Personnel des Signalements** : Suivi en direct du statut des incidents déclarés par le citoyen et affichage de l'unité de secours affectée (ex: *🚒 Camion Citerne 1*).
* **Notification Automatique de Civisme** : Message d'encouragement et de prise en charge envoyé personnellement après chaque alerte SOS.
* **Support Multilingue** : Interface trilingue (**Français**, **Arabe**, **Anglais**).
* **Conseils de Sécurité Hors-ligne** : Guides de prévention et premiers secours consultables sans connexion Internet.

### 💻 2. Tableau de Bord d'Administration (`dashboard_admin/`)
* **Carte de Surveillance en Direct (Leaflet.js)** :
  * 🔴 **Rouge** : Incidents en attente d'intervention.
  * 🔵 **Bleu** : Citoyens bénévoles connectés en ligne avec suivi GPS en direct.
  * 🟢 **Vert** : Citoyens non-bénévoles connectés en ligne.
  * 🟠 **Orange** : Citoyens récemment actifs (< 1h).
  * *Infobulles et modales complètes accessibles directement par clic sur les marqueurs.*
* **Dédoublonnage Géographique Intelligent (200m)** : Regroupement automatique des rapports multiples signalant le même sinistre dans un rayon de 200m sous un incident parent consolidé (galerie d'images agrégée, liste des déclarants, notes vocales).
* **Centre de Diffusion de Notifications Ciblées** :
  * Envoi à tous les citoyens, par gouvernorat, par numéro de téléphone, ou ciblage exclusif : **Tous les bénévoles** ou **Tous les non-bénévoles**.
* **Gestion des Citoyens & Bénévoles** : Suivi des informations médicales, numéros d'urgence, CIN et gestion du statut bénévole.
* **Gestion des Conseils de Sécurité** : CRUD complet bilingue (FR/AR) synchronisé avec les smartphones des citoyens.

### ⚙️ 3. Serveur Backend & API (`backend/`)
* **Framework & Base de Données** : Node.js, Express.js et MongoDB (Mongoose).
* **Temps Réel Bidirectionnel** : Socket.io avec gestion de rooms par utilisateur (`user_<id>`), par gouvernorat, et par groupes (`volunteers`, `non_volunteers`).
* **Sécurité & Authentification** : Tokens signés JWT, hachage sécurisé bcrypt, validation de numéro de téléphone par OTP simulé.
* **Téléversement de Médias** : Middleware Multer pour photos, vidéos et mémos vocaux.

---

## 🛠️ Installation & Démarrage Rapide

### Prérequis
* [Node.js](https://nodejs.org/) (v18 ou supérieur)
* [MongoDB Community Server](https://www.mongodb.com/try/download/community)
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22+)
* [Android Studio](https://developer.android.com/studio) ou un terminal Android physique

---

### Étape 1 : Démarrer le Backend et MongoDB

1. **Lancer MongoDB** sur le port standard `27017` :
   ```bash
   mongod --dbpath <chemin_vers_dossier_data>
   ```

2. **Installer les dépendances et configurer l'environnement** :
   ```bash
   cd backend
   npm install
   cp .env.example .env
   ```

3. **(Optionnel) Peupler la base avec des données de test** :
   ```bash
   node seed.js
   ```

4. **Lancer le serveur** :
   ```bash
   node server.js
   ```
   *Le serveur démarre sur `http://localhost:3000`.*

---

### Étape 2 : Accéder au Tableau de Bord Web

Le tableau de bord est servi directement par le backend :
* Ouvrez votre navigateur sur : **[http://localhost:3000/dashboard](http://localhost:3000/dashboard)**
* Ou ouvrez directement le fichier `dashboard_admin/index.html`.

---

### Étape 3 : Lancer l'Application Mobile (Flutter)

1. **Configurer l'IP de l'API** :
   Ouvrez `mobile_app/lib/config/api_config.dart` et vérifiez que `baseUrl` pointe vers l'adresse IP locale de votre machine (ex: `http://192.168.1.X:3000/api` ou `http://10.0.2.2:3000/api` sur émulateur Android standard).

2. **Installer les packages et lancer** :
   ```bash
   cd mobile_app
   flutter pub get
   flutter run
   ```

---

## 👥 Équipe & Licence

Développé pour l'**Office National de la Protection Civile (Tunisie)**.
Distribué sous licence MIT.
