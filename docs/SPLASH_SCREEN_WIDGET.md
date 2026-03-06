# SplashScreenWidget - Documentation

## 📖 Description

Widget réutilisable pour le Splash Screen de l'application DEM (Delivery Express Mobility).

## ✨ Fonctionnalités

✅ **Animation du logo DEM** - Affichage animé avec effet de zoom et fade  
✅ **Vérification JWT** - Vérifie l'existence d'un token dans SecureStorage  
✅ **Navigation intelligente** - Redirige selon le statut d'authentification :
- Token valide + rôle CLIENT → Home Client
- Token valide + rôle DRIVER/LIVREUR → Home Driver  
- Pas de token → OnboardingScreen
- Erreur → OnboardingScreen (sécurité)

## 📍 Emplacement

```
lib/
└── widgets/
    └── splash_screen_widget.dart
```

## 🎯 Utilisation

### Utilisation basique

```dart
import 'package:flutter/material.dart';
import '../widgets/splash_screen_widget.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreenWidget();
  }
}
```

### Utilisation avec configuration personnalisée

```dart
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreenWidget(
      onboardingRoute: '/onboarding',
      loginRoute: '/login',
      clientHomeRoute: '/clientHome',
      driverHomeRoute: '/livreurHome',
      logoPath: 'assets/images/logo.png',
      animationDuration: 2000, // 2 secondes
      backgroundColor: Colors.white,
    );
  }
}
```

### Utilisation avec thème sombre

```dart
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashScreenWidget(
      backgroundColor: Colors.black,
      logoPath: 'assets/images/logo_white.png',
      animationDuration: 1500,
    );
  }
}
```

## 🔧 Paramètres configurables

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `onboardingRoute` | `String` | `'/onboarding'` | Route vers l'écran d'onboarding |
| `loginRoute` | `String` | `'/login'` | Route vers l'écran de connexion |
| `clientHomeRoute` | `String` | `'/clientHome'` | Route vers le home client |
| `driverHomeRoute` | `String` | `'/livreurHome'` | Route vers le home driver |
| `logoPath` | `String` | `'assets/images/logo.png'` | Chemin vers l'image du logo |
| `animationDuration` | `int` | `1500` | Durée de l'animation (ms) |
| `backgroundColor` | `Color?` | `Colors.white` | Couleur de fond |

## 🔄 Flux de navigation

```
┌─────────────────────┐
│  SplashScreenWidget │
└──────────┬──────────┘
           │
           ▼
    Vérifier JWT dans
    SecureStorage
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
  Token         Pas de
  existe        token
     │           │
     │           └─────► OnboardingScreen
     │
     ▼
  Récupérer
  le rôle
     │
  ┌──┴───┐
  │      │
  ▼      ▼
CLIENT  DRIVER
  │      │
  ▼      ▼
Home   Home
Client Driver
```

## 🛡️ Gestion des erreurs

- **Image non trouvée** : Affiche une icône de secours (camion)
- **Erreur de stockage** : Redirige vers OnboardingScreen
- **Rôle invalide** : Redirige vers OnboardingScreen
- **Widget démonté** : Vérifie `mounted` avant navigation

## 🎨 Animations

### Scale Animation
- **Départ** : 0.7 (70% de la taille)
- **Peak** : 1.1 (110% de la taille)
- **Final** : 1.0 (100% de la taille)
- **Courbe** : `Curves.easeInOut`

### Fade Animation
- **Départ** : 0.0 (transparent)
- **Final** : 1.0 (opaque)
- **Courbe** : `Curves.easeInOut`

## 📱 Responsive Design

Le widget s'adapte automatiquement :
- **Tablettes** (> 600px) : Logo de 250x250
- **Téléphones** (≤ 600px) : Logo de 160x160

## 🧪 Tests

### Test unitaire

```dart
testWidgets('SplashScreenWidget affiche le logo', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SplashScreenWidget(),
    ),
  );

  expect(find.byType(Image), findsOneWidget);
});
```

### Test de navigation

```dart
testWidgets('Redirige vers clientHome si token CLIENT', (tester) async {
  // Mock SecureStorageService
  final mockStorage = MockSecureStorageService();
  when(mockStorage.getAccessToken()).thenAnswer((_) async => 'valid_token');
  when(mockStorage.getRole()).thenAnswer((_) async => 'CLIENT');

  await tester.pumpWidget(
    MaterialApp(
      home: SplashScreenWidget(),
      routes: {
        '/clientHome': (context) => ClientHomePage(),
      },
    ),
  );

  await tester.pumpAndSettle(Duration(seconds: 2));

  expect(find.byType(ClientHomePage), findsOneWidget);
});
```

## 🔗 Dépendances

- `flutter/material.dart` - Framework Flutter
- `SecureStorageService` - Gestion du stockage sécurisé

## 📝 Changelog

### v1.0.0 (4 Mars 2026)
- ✨ Création du widget réutilisable
- ✨ Animation du logo (scale + fade)
- ✨ Vérification JWT
- ✨ Navigation intelligente selon rôle
- ✨ Gestion des erreurs
- ✨ Support responsive
- ✨ Configuration personnalisable

## 👨‍💻 Auteur

Projet Delivery Express Mobility - Frontend Team

## 📄 Licence

Propriétaire - Delivery Express Mobility
