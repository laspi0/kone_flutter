# Shop Manager

Application de gestion de boutique avec authentification multi-roles, point de vente, gestion produits, categories, clients et historique des ventes.

## 🎯 Objectif

Permettre a une boutique de gerer ses ventes quotidiennes avec un POS simple, des roles clairs (superuser/admin/caissier), et des exports Excel/Facture PDF.

## ✅ Fonctionnalites implementees

### 1. Authentification

- Ecran de login avec design moderne
- Validation des champs
- Gestion des erreurs
- Indicateur de chargement
- Basculement visibilité mot de passe

### 2. Gestion des roles

- **Superuser** : Gestion des comptes utilisateurs
- **Admin** : Gestion produits, categories, clients
- **Caissier** : Point de vente et historique
- Badge de role sur l'ecran d'accueil

### 3. Interface

- Ecran d'accueil personnalise
- Menu drawer avec informations utilisateur
- Theme clair/sombre
- Design Material 3

### 4. Securite

- Authentification SQLite
- Comptes de test

### 5. Produits (Admin)

- CRUD produits + categories
- Import Excel (.xlsx) avec validation ligne par ligne
- Export Excel + modele

### 6. Ventes

- Point de vente avec scan code-barres
- Encaissement avec montant recu + monnaie rendue
- Facture PDF (impression/enregistrement)

### 7. Clients

- CRUD clients
- Selection client lors de la vente

### 8. Historique

- Filtrage par dates, caissier, client
- Export Excel des ventes

## 📁 Structure du projet (mise a jour)

```
assets/
└── fonts/
    ├── ArialUnicode.ttf
    └── ArialBold.ttf

lib/
├── main.dart
├── app_router.dart
├── models.dart
├── database.dart
├── auth_provider.dart
├── providers/
│   ├── product_provider.dart
│   └── category_provider.dart
├── data/repositories/
│   ├── product_repository.dart
│   └── category_repository.dart
├── services/
│   └── pdf_service.dart
├── utils/
│   └── import_utils.dart
├── widgets/
│   ├── app_sidebar.dart
│   ├── access_denied.dart
│   └── empty_state.dart
└── screens/
    ├── login_screen.dart
    ├── home_screen.dart
    ├── products_screen.dart
    ├── categories_screen.dart
    ├── sales_screen.dart
    ├── sale_history_screen.dart
    ├── customers_screen.dart
    ├── settings_screen.dart
    ├── user_management_screen.dart
    ├── login/
    │   └── login_widgets.dart
    ├── home/
    │   └── home_widgets.dart
    ├── products/
    │   ├── products_widgets.dart
    │   └── products_dialogs.dart
    ├── categories/
    │   ├── categories_widgets.dart
    │   └── categories_dialogs.dart
    ├── sales/
    │   ├── sales_widgets.dart
    │   └── sales_dialogs.dart
    ├── sale_history/
    │   └── sale_history_widgets.dart
    ├── customers/
    │   ├── customers_widgets.dart
    │   └── customers_dialogs.dart
    ├── settings/
    │   ├── settings_widgets.dart
    │   └── settings_dialogs.dart
    └── user_management/
        ├── user_management_widgets.dart
        └── user_management_dialogs.dart
```

## 🚀 Installation

```bash
flutter pub get
```

### Lancer l'application

```bash
# Desktop
flutter run -d macos
flutter run -d windows
flutter run -d linux

# Mobile
flutter run -d android
flutter run -d ios
```

## 🔐 Comptes de test

| Role      | Username  | Password     |
|-----------|-----------|--------------|
| Superuser | superuser | superuser123 |
| Admin     | admin     | admin123     |
| Caissier  | caissier  | caissier123  |

## 🎨 Fonctionnalites UI (mise a jour)

### Ecran de connexion

- Card avec formulaire centre
- Champs username/password avec validation
- Toggle visibilite mot de passe
- Affichage des erreurs
- Loading indicator

### Ecran d'accueil

- Message de bienvenue personnalise
- Badge de role (Superuser/Admin/Caissier)
- Statistiques (ventes, CA, produits, stock bas)
- Dernieres ventes
- Drawer navigation

### Produits (Admin)

- Import Excel (.xlsx) avec validation stricte
- Parsing nombre tolerant (`12 000`, `12,5`)
- Rapport erreurs/avertissements ligne par ligne
- Export/Modele Excel

## Import/Export Excel (Produits)

Colonnes attendues:
- Nom
- Description
- Prix
- Stock
- Categorie
- Code-barres

Validation:
- Prix > 0
- Stock >= 0
- Nom et categorie obligatoires
- Rapport d'erreurs/avertissements ligne par ligne

## PDF Facture

- Montant recu et monnaie rendue inclus
- Polices Unicode chargees depuis `assets/fonts/`

Note: les polices actuelles (ArialUnicode/ArialBold) proviennent du systeme macOS.  
Pour distribution, remplacez-les par des polices libres (ex: Noto Sans) et mettez a jour `assets/fonts/`.

## 🧪 Tester l'application

1. Lancer l'app
2. Se connecter avec `superuser` / `superuser123`
3. Ouvrir Parametres -> Gestion des utilisateurs
4. Creer/editer un compte Admin ou Caissier
5. Se connecter avec `admin` / `admin123`
6. Tester import Excel sur la page Produits

## 📝 Notes techniques

### Provider

- `AuthProvider` : auth, ventes, clients, utilisateurs, settings
- `ProductProvider` et `CategoryProvider` : data produits/categories

### GoRouter

- Navigation declarative
- Routes definies dans `app_router.dart`

### SQLite

- Base de donnees locale
- Initialisee automatiquement au premier lancement
- Donnees persistantes
