# shop_manager

# Shop Manager - Étape 1 : Login/Logout

## 🎯 Objectif

Mettre en place l'authentification de base avec gestion des rôles (Admin et Caissier).

## ✅ Fonctionnalités implémentées

### 1. Authentification

- ✅ Écran de login avec design moderne
- ✅ Validation des champs
- ✅ Gestion des erreurs
- ✅ Indicateur de chargement
- ✅ Basculement visibilité mot de passe

### 2. Gestion des rôles

- ✅ **Admin** : Accès complet (futur)
- ✅ **Caissier** : Accès limité (futur)
- ✅ Badge de rôle sur l'écran d'accueil
- ✅ Affichage des permissions

### 3. Interface

- ✅ Écran d'accueil personnalisé
- ✅ Menu drawer avec informations utilisateur
- ✅ Thème clair/sombre
- ✅ Design Material 3

### 4. Sécurité (Basique)

- ✅ Authentification SQLite
- ✅ 3 comptes de test
- ⚠️ Note : Mot de passe en clair (à améliorer en production avec bcrypt)

## 📁 Structure du projet

```
lib/
├── main.dart                 # Point d'entrée
├── models.dart              # Modèle User
├── database.dart            # SQLite helper
├── auth_provider.dart       # State management (Provider)
├── app_router.dart          # Navigation (GoRouter)
└── screens/
    ├── login_screen.dart    # Écran de connexion
    └── home_screen.dart     # Écran d'accueil
```

**Total : 7 fichiers**

## 🚀 Installation

### 1. Créer le projet

```bash
flutter create shop_manager
cd shop_manager
```

### 2. Structure des dossiers

```bash
mkdir -p lib/screens
```

### 3. Copier les fichiers

Remplacez `pubspec.yaml` puis copiez dans `lib/` :

- `main.dart`
- `models.dart`
- `database.dart`
- `auth_provider.dart`
- `app_router.dart`

Dans `lib/screens/` :

- `login_screen.dart`
- `home_screen.dart`

### 4. Installer les dépendances

```bash
flutter pub get
```

### 5. Lancer l'application

```bash
# Desktop
flutter run -d windows
flutter run -d linux
flutter run -d macos

# Mobile
flutter run -d android
flutter run -d ios
```

## 🔐 Comptes de test


| Rôle    | Username | Password    |
| -------- | -------- | ----------- |
| Admin    | admin    | admin123    |
| Caissier | caissier | caissier123 |
| Caissier | marie    | marie123    |

## 🎨 Fonctionnalités UI

### Écran de connexion

- Gradient de fond
- Card avec formulaire centré
- Champs username et password avec validation
- Toggle visibilité mot de passe
- Affichage des erreurs en temps réel
- Loading indicator
- Liste des comptes de test

### Écran d'accueil

- Avatar avec icône selon le rôle
- Message de bienvenue personnalisé
- Badge de rôle (Admin/Caissier)
- Liste des permissions
- Bouton de déconnexion
- Drawer avec navigation
- Toggle thème clair/sombre

## 🧪 Tester l'application

1. **Lancer l'app** → Écran de login s'affiche
2. **Se connecter** avec `admin` / `admin123`
3. **Vérifier** l'écran d'accueil avec badge "Administrateur"
4. **Tester** le toggle thème (bouton en haut)
5. **Ouvrir** le drawer (menu hamburger)
6. **Se déconnecter** (bouton rouge ou via drawer)
7. **Se reconnecter** avec `caissier` / `caissier123`
8. **Vérifier** le badge "Caissier" et permissions limitées

## 🔄 Prochaines étapes

### Étape 2 : Dashboard

- Tableau de bord avec statistiques
- Widgets de statistiques
- Navigation vers les autres écrans

### Étape 3 : Gestion des clients

- Liste des clients
- CRUD complet (Create, Read, Update, Delete)
- Recherche

### Étape 4 : Gestion des produits

- Liste des produits
- CRUD complet
- Gestion des catégories
- Gestion du stock

### Étape 5 : Système de vente

- Panier
- Sélection client
- Sélection produits
- Validation vente
- Mise à jour stock

### Étape 6 : Historique

- Liste des ventes
- Détails des ventes
- Filtres et recherche

## 📝 Notes techniques

### Provider

- `AuthProvider` gère l'état d'authentification
- `notifyListeners()` met à jour l'UI automatiquement
- `Consumer` écoute les changements

### GoRouter

- Navigation déclarative
- Routes définies dans `app_router.dart`
- `context.go()` pour naviguer

### SQLite

- Base de données locale
- Initialisée automatiquement au premier lancement
- Données persistantes

### Sécurité

⚠️ **Important** : Les mots de passe sont stockés en clair pour la démo.
En production, utilisez `bcrypt`, `argon2` ou similaire.

## 🐛 Dépannage

### Erreur SQLite sur desktop

```bash
flutter pub add sqflite_common_ffi
```

### Hot reload ne fonctionne pas

Redémarrez l'app avec `R` dans le terminal.

### Base de données corrompue

Supprimez la BDD et relancez :

- Windows : `%USERPROFILE%\Documents\shop_manager.db`
- Linux/Mac : `~/Documents/shop_manager.db`

## ✨ Prêt pour l'étape 2 ?

Une fois cette étape validée, nous passerons au **Dashboard** avec :

- Statistiques en temps réel
- Cartes interactives
- Actions rapides
- Navigation vers les modules

**Testez bien cette étape avant de continuer !** 🚀

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
