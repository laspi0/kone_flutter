# shop_manager

# Shop Manager

## 🎯 Objectif

Application de gestion de boutique avec authentification multi-rôles, gestion produits, ventes, clients et outils d'administration.

## ✅ Fonctionnalités implémentées

### 1. Authentification

- ✅ Écran de login avec design moderne
- ✅ Validation des champs
- ✅ Gestion des erreurs
- ✅ Indicateur de chargement
- ✅ Basculement visibilité mot de passe

### 2. Gestion des rôles

- ✅ **Superuser** : Gestion des comptes utilisateurs
- ✅ **Admin** : Gestion produits, catégories, clients
- ✅ **Caissier** : Point de vente et historique
- ✅ Badge de rôle sur l'écran d'accueil

### 3. Interface

- ✅ Écran d'accueil personnalisé
- ✅ Menu drawer avec informations utilisateur
- ✅ Thème clair/sombre
- ✅ Design Material 3

### 4. Sécurité (Basique)

- ✅ Authentification SQLite
- ✅ Comptes de test
- ⚠️ Note : Mot de passe en clair (à améliorer en production avec bcrypt)

### 5. Produits (Admin)

- ✅ CRUD produits + catégories
- ✅ Import Excel (.xlsx) avec validation
- ✅ Export modèle Excel

## 📁 Structure du projet

```
lib/
├── main.dart                      # Point d'entrée
├── models.dart                    # Modèles
├── database.dart                  # SQLite helper
├── auth_provider.dart             # State management (Provider)
├── app_router.dart                # Navigation (GoRouter)
├── widgets/
│   └── app_sidebar.dart           # Sidebar
└── screens/
    ├── login_screen.dart          # Écran de connexion
    ├── home_screen.dart           # Écran d'accueil
    ├── products_screen.dart       # Produits + import Excel
    ├── categories_screen.dart     # Catégories
    ├── sales_screen.dart          # Ventes
    ├── sale_history_screen.dart   # Historique des ventes
    ├── customers_screen.dart      # Clients
    ├── settings_screen.dart       # Paramètres
    └── user_management_screen.dart# Gestion utilisateurs
```

**Note** : La structure peut évoluer avec les fonctionnalités.

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


| Rôle      | Username  | Password      |
| --------- | --------- | ------------- |
| Superuser | superuser | superuser123  |
| Admin     | admin     | admin123      |
| Caissier  | caissier  | caissier123   |
| Caissier  | marie     | marie123      |

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
- Badge de rôle (Superuser/Admin/Caissier)
- Liste des permissions
- Bouton de déconnexion
- Drawer avec navigation
- Toggle thème clair/sombre

### Produits (Admin)

- Import Excel (.xlsx) tolérant aux variations d’en-têtes
- Parsing nombre tolérant (`12 000`, `12,5`)
- Rapport d’erreurs et avertissements “nom proche”

## 🧪 Tester l'application

1. **Lancer l'app** → Écran de login s'affiche
2. **Se connecter** avec `superuser` / `superuser123`
3. **Ouvrir** `Paramètres` → `Gestion des utilisateurs`
4. **Créer/éditer** un compte Admin ou Caissier
5. **Se connecter** avec `admin` / `admin123`
6. **Tester** import Excel sur la page Produits

## 🔄 Prochaines étapes

### Idées futures

- Historique détaillé des actions Superuser
- Export CSV/XLSX des produits
- Rôles/permissions personnalisés

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
